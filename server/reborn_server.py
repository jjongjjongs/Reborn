#!/usr/bin/env python3
"""Reborn — private revival server for Special Soldier (com.wellgames.ss 3.4.7).

Speaks the game's HTTP envelope so the client gets past the connection /
login flow. Pure stdlib (no deps). Point the device's `fps.ss.nexon.com` at
the machine running this (see server/README.md); every /game/*.php and
/init/*.php request lands here.

Wire format (reverse-engineered — see analysis/README.md):
  request : GET  /game/<name>.php?a=<guid>&b=<payload>&c=1
            POST /game/<name>.php   form fields a,b,c
            b = base64url( M_WEB_REQUEST json )  with = + /  ->  %3D %2B %2F
            M_WEB_REQUEST = {MD5,TIME,GUID,TOKEN,LANG,CODE,DATA,CB_NAME}
            DATA is itself a JSON string (the per-protocol arguments)
  response: body = M_WEB_RESPONSE json
            {CODE, RESULT, DATA, TIME, CB_NAME, ERROR}
            RESULT: 0=PASS(ok) 1=FAIL 2=SUCCESS ; DATA is a JSON string ;
            ERROR null on success, else M_ERROR {TYPE,NO,TKEY,MSG,PARAM,PROTOCOL}

Every request is logged with its decoded envelope so responses can be filled
in iteratively against real device traffic. Unknown protocols return an empty
PASS envelope and are logged, so the client keeps moving while we learn them.
"""
import base64
import json
import os
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

HERE = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(HERE, "requests.log")

# RESULT enum (M_WEB_RESPONSE.TYPE_RESULT)
PASS, FAIL, SUCCESS = 0, 1, 2

# URL handed back by connection_string. Empty -> echo the Host the client
# used, so a pure DNS redirect keeps every later call coming here too.
OVERRIDE_URL = os.environ.get("REBORN_URL", "")


def now_str():
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")


def b_decode(b):
    """Decode the `b` request field to the M_WEB_REQUEST dict (best effort)."""
    if b is None:
        return None, None
    raw = b
    s = b.replace("%3D", "=").replace("%2B", "+").replace("%2F", "/")
    s = s.replace("-", "+").replace("_", "/")  # tolerate std base64url too
    try:
        pad = "=" * (-len(s) % 4)
        txt = base64.b64decode(s + pad).decode("utf-8", "replace")
        return json.loads(txt), txt
    except Exception as e:
        return None, f"<decode failed: {e}> raw={raw[:120]}"


def inner(env):
    """Parse the DATA field (a JSON string) of a decoded envelope."""
    if not env:
        return {}
    d = env.get("DATA")
    if isinstance(d, str) and d:
        try:
            return json.loads(d)
        except Exception:
            return {"_raw": d}
    return d or {}


def envelope(code, data, result=PASS, error=None, cb_name=None):
    """Build an M_WEB_RESPONSE body. `data` is a dict -> serialized to a string."""
    return json.dumps({
        "CODE": code,
        "RESULT": result,
        "DATA": json.dumps(data, ensure_ascii=False) if data is not None else "",
        "TIME": str(int(time.time())),
        "CB_NAME": cb_name,
        "ERROR": error,
    }, ensure_ascii=False)


def make_error(no, tkey, msg, protocol):
    return {"TYPE": 0, "NO": no, "TKEY": tkey, "MSG": msg, "PARAM": None, "PROTOCOL": protocol}


# ---------------------------------------------------------------- handlers
# Each handler: (guid, args_dict, host) -> (data_dict, result, error)
# Fill these in against real traffic; start minimal to advance the client.

def h_connection_string(guid, args, host):
    url = OVERRIDE_URL or f"http://{host}"
    return {"URL": url, "NOTICE": "", "STATE": "live"}, PASS, None


DEFAULT_GUID = 1000001


def h_create(guid, args, host):
    # U_Lobby_Loading.CB_CREATE_ACCOUNT reads GUID, TOKEN, NEWACCOUNT, AGREE.
    return {
        "GUID": DEFAULT_GUID,
        "TOKEN": 1,
        "NEWACCOUNT": 1,
        "AGREE": 1,
        "AGREE_VER": 1,
    }, PASS, None


def h_login(guid, args, host):
    # U_Lobby_Loading.CB_LOGIN: absence of LEAVE_DATE => no deletion-recovery
    # prompt; on success it logs "Login Success" and moves to RequestMyinfo.
    return {"NOW_TIC": int(time.time()), "NEW_USER_CARE": 0}, PASS, None


def _money(gold=0, cash=0, scoin=0, heart=0, coin=0):
    # M_MONEY: properties GOLD/CASH/SCOIN/HEART/COIN (plain ints over ObscuredInt).
    return {"GOLD": gold, "CASH": cash, "SCOIN": scoin, "HEART": heart, "COIN": coin}


def _record():
    # M_RECORD_PLAYER: all stat ints + EXP (property over ObscuredInt _EXP).
    keys = ("KILL DEATH CLANSHOT HEADSHOT RIFLE MACHINE SNIPER PISTOL SHOTGUN "
            "KNIFE SWORD GRENADE TEAM SUICIDE ASSIST DUALPISTOLS CROSSBOW ROCKET "
            "DUALRIFLES THROW_WEAPON PVE2_BEST_TIME PVE2_BEST_SCORE COLLECTION_POINT "
            "DINO_SCORE EXP").split()
    return {k: 0 for k in keys}


def _inven():
    # M_INVEN: empty lists so the loadout UI has valid (if empty) collections.
    return {
        "WEAPON_LIST": [], "CHARACTER_LIST": [], "CHARACTER_SKIN_LIST": [],
        "GRENADE": "", "PVP_INVENTORY_MAXSIZE": 100, "PVE_INVENTORY_MAXSIZE": 100,
        "INVENTORY_EXPANSION_INFO": [],
        "WEAPON_1": 0, "WEAPON_2": 0, "WEAPON_3": 0,
        "CHARACTER": 0, "CHARACTER_SKINID": 0,
    }


def _player(guid):
    # M_PLAYER (parsed by MyJson.UpdatePlayer). Uppercase keys = field names;
    # nested objects are minimal-but-valid so the lobby can populate without
    # null collections. Fill real values against device logs (requests.log).
    return {
        "ID": guid or DEFAULT_GUID,
        "NAME": "Soldier",
        "MONEY": _money(),
        "RECORD": _record(),
        "INVEN": _inven(),
        "PVE_INVEN": _inven(),
        "CLAN": None,
        "CLAN_TYPE": 0,
        "GACHA": {"TIME": "", "CASH": 0},
        "FIRST": [], "EVENT": [], "ONEYEAR": [], "MEGA": [], "NEWBE": [], "MONTH": [],
        "RECEIPTS": [],
        "NCS_TOKEN": "",
        "FRIEND_DENY": False, "CLAN_DENY": False, "PARTY_DENY": False,
        "MAIN_ICON_ID": 0, "FRIEND_STATE": 0, "IS_RETURN": False,
        "TITLE": 0,
        "BOOSTER": [],
        "VIP_LIST": [], "VIP2_LIST": [], "VIP3_LIST": [],
        "VIP4_LIST": [], "VIP6_LIST": [], "VIP7_LIST": [],
        "ATTEND_INFO": {"ATTEND": [], "THIS_MONTH": 0, "TODAY": 0, "ACC1020": [], "COUNT": 0},
        "STATUS": 0,
    }


def h_myinfo(guid, args, host):
    return _player(guid), PASS, None


def h_money(guid, args, host):
    return _money(), PASS, None


HANDLERS = {
    "connection_string": h_connection_string,
    "login": h_login,
    "create": h_create,
    "myinfo": h_myinfo,
    "money": h_money,
}


def protocol_of(path):
    """/game/login.php -> 'login'."""
    base = path.rsplit("/", 1)[-1]
    return base[:-4] if base.endswith(".php") else base


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):  # silence default stderr spam
        pass

    def _params(self):
        u = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(u.query).items()}
        if self.command == "POST":
            n = int(self.headers.get("Content-Length", 0) or 0)
            body = self.rfile.read(n).decode("utf-8", "replace") if n else ""
            q.update({k: v[0] for k, v in parse_qs(body).items()})
        return u.path, q

    def _handle(self):
        path, q = self._params()
        proto = protocol_of(path)
        guid_raw = q.get("a")
        try:
            guid = int(guid_raw) if guid_raw not in (None, "") else None
        except ValueError:
            guid = None
        env, env_txt = b_decode(q.get("b"))
        args = inner(env)
        host = self.headers.get("Host", "").split(":")[0] or "127.0.0.1"
        self._record(proto, path, guid, env_txt, args)

        handler = HANDLERS.get(proto)
        if handler:
            data, result, error = handler(guid, args, host)
        else:
            data, result, error = {}, PASS, None  # keep the client moving
        body = envelope(env.get("CODE", proto) if env else proto, data, result, error)
        raw = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    do_GET = _handle
    do_POST = _handle

    def _record(self, proto, path, guid, env_txt, args):
        line = (f"[{now_str()}] {self.command} {path}  proto={proto} guid={guid}\n"
                f"    envelope={env_txt}\n"
                f"    args={json.dumps(args, ensure_ascii=False)}\n")
        print(line, end="", flush=True)
        try:
            with open(LOG, "a", encoding="utf-8") as f:
                f.write(line)
        except OSError:
            pass


def main():
    port = int(os.environ.get("REBORN_PORT", "80"))
    addr = os.environ.get("REBORN_BIND", "0.0.0.0")
    srv = ThreadingHTTPServer((addr, port), Handler)
    print(f"Reborn server on http://{addr}:{port}  (override URL: {OVERRIDE_URL or '<echo Host>'})")
    print(f"logging to {LOG}")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
