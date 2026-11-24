#!/usr/bin/env python3
"""Tiny DNS redirector so an unrooted phone reaches the Reborn server.

Answers A queries for the game's hosts with THIS machine's LAN IP; forwards
everything else to a real upstream resolver so the phone's other traffic
keeps working. Run it on a PC on the same Wi-Fi, then set the phone's Wi-Fi
DNS to that PC. Pure stdlib.

  sudo REBORN_IP=192.168.0.10 python3 server/dns_redirect.py

Env:
  REBORN_IP   LAN IP to hand back for the game hosts (default: autodetect)
  DNS_UPSTREAM  upstream resolver for everything else (default 8.8.8.8)
  DNS_BIND / DNS_PORT  (default 0.0.0.0 / 53)
  REBORN_HOSTS  extra comma-separated host suffixes to redirect
"""
import os
import socket
import struct
import sys

# Hosts whose A records we hijack. Suffix match (so sub.host also matches).
REDIRECT = [
    "fps.ss.nexon.com",       # DEFAULT live server (the one the client uses)
    "fps.ss-stg.nexon.com",
    "fps.wellgames.kr",
    "fps-en.wellgames.kr",
    "fps.dev.wgss.kr",
    "fps.stg-beta.wgss.kr",
    "ss-cdn.wellgames.kr",
]
for extra in os.environ.get("REBORN_HOSTS", "").split(","):
    if extra.strip():
        REDIRECT.append(extra.strip().lower())

UPSTREAM = os.environ.get("DNS_UPSTREAM", "8.8.8.8")


def autodetect_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect((UPSTREAM, 53))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


REBORN_IP = os.environ.get("REBORN_IP") or autodetect_ip()


def parse_qname(data, off):
    labels = []
    while True:
        n = data[off]
        if n == 0:
            off += 1
            break
        if n & 0xC0:  # compression pointer (shouldn't appear in a question)
            off += 2
            break
        labels.append(data[off + 1:off + 1 + n].decode("latin1"))
        off += 1 + n
    return ".".join(labels), off


def build_a_answer(query, ip):
    # Echo header with QR=1, AA=1, ANCOUNT=1; copy question; append one A RR.
    tid = query[:2]
    flags = b"\x81\x80"  # standard response, no error
    qd = query[4:6]
    header = tid + flags + qd + b"\x00\x01" + b"\x00\x00" + b"\x00\x00"
    # question section = everything after the 12-byte header up to end of qname+qtype+qclass
    _, qend = parse_qname(query, 12)
    question = query[12:qend + 4]
    rr = (b"\xc0\x0c" + b"\x00\x01" + b"\x00\x01" + b"\x00\x00\x00\x3c"
          + b"\x00\x04" + socket.inet_aton(ip))
    return header + question + rr


def forward(query):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(4)
    try:
        s.sendto(query, (UPSTREAM, 53))
        return s.recvfrom(4096)[0]
    except OSError:
        return None
    finally:
        s.close()


def wants_redirect(name):
    name = name.lower().rstrip(".")
    return any(name == h or name.endswith("." + h) or name == h for h in REDIRECT)


def main():
    bind = os.environ.get("DNS_BIND", "0.0.0.0")
    port = int(os.environ.get("DNS_PORT", "53"))
    srv = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        srv.bind((bind, port))
    except PermissionError:
        sys.exit(f"bind {bind}:{port} needs root (port 53). Try: sudo python3 {sys.argv[0]}")
    print(f"DNS redirector on {bind}:{port}")
    print(f"  game hosts -> {REBORN_IP}")
    print(f"  everything else -> {UPSTREAM}")
    print(f"  redirecting: {', '.join(REDIRECT)}")
    while True:
        try:
            data, addr = srv.recvfrom(4096)
        except OSError:
            continue
        if len(data) < 12:
            continue
        try:
            name, _ = parse_qname(data, 12)
            qtype = struct.unpack_from(">H", data, parse_qname(data, 12)[1])[0]
        except Exception:
            name, qtype = "", 0
        if qtype == 1 and wants_redirect(name):  # A record we hijack
            srv.sendto(build_a_answer(data, REBORN_IP), addr)
            print(f"  redirect {name} -> {REBORN_IP}")
        else:
            resp = forward(data)
            if resp:
                srv.sendto(resp, addr)


if __name__ == "__main__":
    main()
