// Reborn embedded server — a tiny stateful HTTP server that runs INSIDE the
// game process (no PC, no Termux, no internet). A constructor starts it on a
// background thread bound to 127.0.0.1 when this .so is loaded (the APK's
// libil2cpp.so is patched to list it as NEEDED, and to send the game's
// requests to this port). Profile state persists to the app's files dir, so
// progress survives restarts — all within the APK.
//
// Scope: login -> lobby -> shop/inventory -> PvE/bot/practice. Real-time PvP
// against humans is intentionally out of scope (needs a real multiplayer
// server). Built for arm64-v8a and armeabi-v7a by the GitHub Actions runner
// (it has the Android NDK); see .github/workflows/embedded.yml.
//
// Wire format (see analysis/README.md):
//   request : GET/POST /game/<proto>.php  with fields a=guid, b=base64url(env), c=1
//   response: M_WEB_RESPONSE json {CODE,RESULT,DATA,TIME,CB_NAME,ERROR}
//             RESULT 0=PASS; DATA is a JSON string.

#include <arpa/inet.h>
#include <netinet/in.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#ifndef REBORN_PORT
#define REBORN_PORT 42427
#endif
#ifndef FILES_DIR
#define FILES_DIR "/data/data/com.wellgames.ss/files"
#endif
#ifndef PROFILE_PATH
#define PROFILE_PATH FILES_DIR "/reborn_profile.txt"
#endif
#ifndef LOG_PATH
// External storage so a file-manager app can read it even after a crash
// (the app has WRITE_EXTERNAL_STORAGE and targets SDK 28 = legacy storage).
#define LOG_PATH "/sdcard/reborn_requests.log"
#endif

// Append one line to the request log. Readable two ways, no PC needed:
//   - file manager: /sdcard/reborn_requests.log  (survives a crash)
//   - browser:      http://127.0.0.1:<port>/__log (while the app is running)
static void log_line(const char *proto, int handled, const char *env) {
    FILE *f = fopen(LOG_PATH, "a");
    if (!f) return;
    char head[200];
    int i = 0;
    for (const char *p = env; *p && i < 180; p++) {   // one line, trimmed
        head[i++] = (*p == '\n' || *p == '\r') ? ' ' : *p;
    }
    head[i] = 0;
    fprintf(f, "%ld  %-20s %s  %s\n", (long)time(NULL), proto,
            handled ? "OK " : "STUB", head);
    fclose(f);
}

// ------------------------------------------------------------ persistence
// Minimal line-based store so we avoid a JSON parser in C. Extend as needed.
typedef struct {
    int guid, token;
    int gold, cash, scoin, heart, coin;
    int level, exp;
    int created;
    char name[32];
} Profile;

static Profile g_prof;
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;

static void profile_defaults(Profile *p) {
    memset(p, 0, sizeof(*p));
    p->guid = 1000001;
    p->token = 1;
    p->gold = 5000;
    p->cash = 0;
    p->scoin = 0;
    p->level = 1;
    p->exp = 0;
    p->created = 0;
    snprintf(p->name, sizeof(p->name), "%s", "Soldier");
}

static void profile_load(Profile *p) {
    profile_defaults(p);
    FILE *f = fopen(PROFILE_PATH, "r");
    if (!f) return;
    char line[128];
    while (fgets(line, sizeof(line), f)) {
        char key[32];
        char val[64];
        if (sscanf(line, "%31[^=]=%63[^\n]", key, val) != 2) continue;
        if (!strcmp(key, "guid")) p->guid = atoi(val);
        else if (!strcmp(key, "token")) p->token = atoi(val);
        else if (!strcmp(key, "gold")) p->gold = atoi(val);
        else if (!strcmp(key, "cash")) p->cash = atoi(val);
        else if (!strcmp(key, "scoin")) p->scoin = atoi(val);
        else if (!strcmp(key, "heart")) p->heart = atoi(val);
        else if (!strcmp(key, "coin")) p->coin = atoi(val);
        else if (!strcmp(key, "level")) p->level = atoi(val);
        else if (!strcmp(key, "exp")) p->exp = atoi(val);
        else if (!strcmp(key, "created")) p->created = atoi(val);
        else if (!strcmp(key, "name")) snprintf(p->name, sizeof(p->name), "%s", val);
    }
    fclose(f);
}

static void profile_save(const Profile *p) {
    mkdir(FILES_DIR, 0771);
    FILE *f = fopen(PROFILE_PATH, "w");
    if (!f) return;
    fprintf(f, "guid=%d\ntoken=%d\ngold=%d\ncash=%d\nscoin=%d\nheart=%d\ncoin=%d\n"
               "level=%d\nexp=%d\ncreated=%d\nname=%s\n",
            p->guid, p->token, p->gold, p->cash, p->scoin, p->heart, p->coin,
            p->level, p->exp, p->created, p->name);
    fclose(f);
}

// ------------------------------------------------------------ base64url
static int b64val(int c) {
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+' || c == '-') return 62;
    if (c == '/' || c == '_') return 63;
    return -1;
}

// Decode the `b` field (percent-escaped base64url) into out. Returns length.
static int decode_b(const char *b, char *out, int outcap) {
    char tmp[8192];
    int n = 0;
    for (int i = 0; b[i] && n < (int)sizeof(tmp) - 1; i++) {
        if (b[i] == '%' && b[i + 1] && b[i + 2]) {
            int hi = b[i + 1], lo = b[i + 2];
            char dec[4] = {0};
            unsigned v;
            dec[0] = hi; dec[1] = lo;
            sscanf(dec, "%2x", &v);
            tmp[n++] = (char)v;
            i += 2;
        } else {
            tmp[n++] = b[i];
        }
    }
    tmp[n] = 0;
    int o = 0, bits = 0, acc = 0;
    for (int i = 0; i < n; i++) {
        int v = b64val((unsigned char)tmp[i]);
        if (v < 0) continue;
        acc = (acc << 6) | v;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            if (o < outcap - 1) out[o++] = (char)((acc >> bits) & 0xFF);
        }
    }
    out[o] = 0;
    return o;
}

// Tiny helper: find "KEY":"value" or "KEY":value (number) in a json blob.
__attribute__((unused)) static int json_str(const char *json, const char *key, char *out, int cap) {
    char pat[64];
    snprintf(pat, sizeof(pat), "\"%s\"", key);
    const char *p = strstr(json, pat);
    if (!p) return 0;
    p += strlen(pat);
    while (*p == ' ' || *p == ':') p++;
    if (*p == '"') {
        p++;
        int i = 0;
        while (*p && *p != '"' && i < cap - 1) out[i++] = *p++;
        out[i] = 0;
    } else {
        int i = 0;
        while (*p && *p != ',' && *p != '}' && i < cap - 1) out[i++] = *p++;
        out[i] = 0;
    }
    return 1;
}

// ------------------------------------------------------------ responses
// Write an M_WEB_RESPONSE, escaping the inner DATA json into the envelope.
static void send_envelope(int fd, const char *code, const char *inner) {
    char esc[16384];
    int o = 0;
    for (int i = 0; inner[i] && o < (int)sizeof(esc) - 2; i++) {
        char c = inner[i];
        if (c == '"' || c == '\\') esc[o++] = '\\';
        esc[o++] = c;
    }
    esc[o] = 0;
    char body[20000];
    int n = snprintf(body, sizeof(body),
        "{\"CODE\":\"%s\",\"RESULT\":0,\"DATA\":\"%s\",\"TIME\":\"%ld\","
        "\"CB_NAME\":null,\"ERROR\":null}",
        code, esc, (long)time(NULL));
    char hdr[256];
    int hn = snprintf(hdr, sizeof(hdr),
        "HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\n"
        "Content-Length: %d\r\nConnection: close\r\n\r\n", n);
    write(fd, hdr, hn);
    write(fd, body, n);
}

static void inner_money(char *buf, int cap, const Profile *p) {
    snprintf(buf, cap, "{\"GOLD\":%d,\"CASH\":%d,\"SCOIN\":%d,\"HEART\":%d,\"COIN\":%d}",
             p->gold, p->cash, p->scoin, p->heart, p->coin);
}

static void inner_player(char *buf, int cap, const Profile *p) {
    char money[128];
    inner_money(money, sizeof(money), p);
    snprintf(buf, cap,
        "{\"ID\":%d,\"NAME\":\"%s\",\"MONEY\":%s,"
        "\"RECORD\":{\"KILL\":0,\"DEATH\":0,\"HEADSHOT\":0,\"ASSIST\":0,\"EXP\":%d},"
        "\"INVEN\":{\"WEAPON_LIST\":[],\"CHARACTER_LIST\":[],\"CHARACTER_SKIN_LIST\":[],"
        "\"GRENADE\":\"\",\"PVP_INVENTORY_MAXSIZE\":100,\"PVE_INVENTORY_MAXSIZE\":100,"
        "\"INVENTORY_EXPANSION_INFO\":[],\"WEAPON_1\":0,\"WEAPON_2\":0,\"WEAPON_3\":0,"
        "\"CHARACTER\":0,\"CHARACTER_SKINID\":0},"
        "\"PVE_INVEN\":{\"WEAPON_LIST\":[],\"CHARACTER_LIST\":[],\"CHARACTER_SKIN_LIST\":[],"
        "\"INVENTORY_EXPANSION_INFO\":[]},"
        "\"CLAN\":null,\"CLAN_TYPE\":0,\"GACHA\":{\"TIME\":\"\",\"CASH\":0},"
        "\"FIRST\":[],\"EVENT\":[],\"ONEYEAR\":[],\"MEGA\":[],\"NEWBE\":[],\"MONTH\":[],"
        "\"RECEIPTS\":[],\"NCS_TOKEN\":\"\","
        "\"FRIEND_DENY\":false,\"CLAN_DENY\":false,\"PARTY_DENY\":false,"
        "\"MAIN_ICON_ID\":0,\"FRIEND_STATE\":0,\"IS_RETURN\":false,\"TITLE\":0,"
        "\"BOOSTER\":[],\"VIP_LIST\":[],\"VIP2_LIST\":[],\"VIP3_LIST\":[],"
        "\"VIP4_LIST\":[],\"VIP6_LIST\":[],\"VIP7_LIST\":[],"
        "\"ATTEND_INFO\":{\"ATTEND\":[],\"THIS_MONTH\":0,\"TODAY\":0,\"ACC1020\":[],\"COUNT\":0},"
        "\"STATUS\":0}",
        p->guid, p->name, money, p->exp);
}

// Route one protocol to its response. Returns via send_envelope.
static void handle(int fd, const char *proto, const char *env) {
    char inner[16384];
    int handled = 1;
    pthread_mutex_lock(&g_lock);

    if (!strcmp(proto, "connection_string")) {
        snprintf(inner, sizeof(inner),
                 "{\"URL\":\"http://127.0.0.1:%d\",\"NOTICE\":\"\",\"STATE\":\"live\"}",
                 REBORN_PORT);
    } else if (!strcmp(proto, "create")) {
        if (!g_prof.created) { g_prof.created = 1; profile_save(&g_prof); }
        snprintf(inner, sizeof(inner),
                 "{\"GUID\":%d,\"TOKEN\":%d,\"NEWACCOUNT\":1,\"AGREE\":1,\"AGREE_VER\":1}",
                 g_prof.guid, g_prof.token);
    } else if (!strcmp(proto, "login")) {
        snprintf(inner, sizeof(inner), "{\"NOW_TIC\":%ld,\"NEW_USER_CARE\":0}", (long)time(NULL));
    } else if (!strcmp(proto, "myinfo")) {
        inner_player(inner, sizeof(inner), &g_prof);
    } else if (!strcmp(proto, "money")) {
        inner_money(inner, sizeof(inner), &g_prof);
    } else if (!strcmp(proto, "shop_list") || !strcmp(proto, "shop_ver")) {
        snprintf(inner, sizeof(inner), "{\"LIST\":[],\"VER\":1}");
    } else {
        // keep the client moving; empty PASS payload
        snprintf(inner, sizeof(inner), "{}");
        handled = 0;
    }

    pthread_mutex_unlock(&g_lock);
    log_line(proto, handled, env);
    send_envelope(fd, proto, inner);
}

// ------------------------------------------------------------ http loop
static void extract_proto(const char *path, char *out, int cap) {
    const char *slash = strrchr(path, '/');
    const char *base = slash ? slash + 1 : path;
    int i = 0;
    while (base[i] && base[i] != '.' && base[i] != '?' && i < cap - 1) {
        out[i] = base[i];
        i++;
    }
    out[i] = 0;
}

static void serve(int fd) {
    char req[16384];
    int total = 0, n;
    // read headers (+ a bit of body for small POSTs)
    while ((n = read(fd, req + total, sizeof(req) - 1 - total)) > 0) {
        total += n;
        req[total] = 0;
        if (strstr(req, "\r\n\r\n") && total > 16) {
            // if POST, try to read declared body
            char *cl = strstr(req, "Content-Length:");
            if (cl) {
                int len = atoi(cl + 15);
                char *body = strstr(req, "\r\n\r\n") + 4;
                int have = total - (int)(body - req);
                while (have < len && total < (int)sizeof(req) - 1) {
                    n = read(fd, req + total, sizeof(req) - 1 - total);
                    if (n <= 0) break;
                    total += n; req[total] = 0; have += n;
                }
            }
            break;
        }
        if (total >= (int)sizeof(req) - 1) break;
    }
    if (total <= 0) return;

    // request line: "GET /game/login.php?a=..&b=..&c=1 HTTP/1.1"
    char path[4096] = {0};
    sscanf(req, "%*s %4095s", path);
    char proto[64];
    extract_proto(path, proto, sizeof(proto));

    // Browser diagnostics (open these in the phone's browser, no PC needed):
    //   http://127.0.0.1:42427/__ping  -> "reborn ok"
    //   http://127.0.0.1:42427/__log   -> the request history (last proto = crash point)
    if (!strcmp(proto, "__ping")) {
        const char *ok = "reborn ok\n";
        char h[160];
        int hn = snprintf(h, sizeof(h), "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
                          "Content-Length: %zu\r\nConnection: close\r\n\r\n", strlen(ok));
        write(fd, h, hn); write(fd, ok, strlen(ok));
        return;
    }
    if (!strcmp(proto, "__log")) {
        FILE *lf = fopen(LOG_PATH, "r");
        char buf[65536];
        int n = lf ? (int)fread(buf, 1, sizeof(buf), lf) : 0;
        if (lf) fclose(lf);
        char h[200];
        int hn = snprintf(h, sizeof(h), "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\n"
                          "Content-Length: %d\r\nConnection: close\r\n\r\n", n);
        write(fd, h, hn);
        if (n > 0) write(fd, buf, n);
        return;
    }

    // find b= (query for GET, body for POST)
    char env[12288] = {0};
    const char *b = strstr(path, "b=");
    if (!b) {
        char *body = strstr(req, "\r\n\r\n");
        if (body) b = strstr(body, "b=");
    }
    if (b) {
        b += 2;
        char raw[8192];
        int i = 0;
        while (b[i] && b[i] != '&' && i < (int)sizeof(raw) - 1) { raw[i] = b[i]; i++; }
        raw[i] = 0;
        decode_b(raw, env, sizeof(env));
    }
    handle(fd, proto, env);
}

static void *server_main(void *arg) {
    (void)arg;
    int s = socket(AF_INET, SOCK_STREAM, 0);
    if (s < 0) return NULL;
    int one = 1;
    setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(REBORN_PORT);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (bind(s, (struct sockaddr *)&addr, sizeof(addr)) < 0) { close(s); return NULL; }
    if (listen(s, 16) < 0) { close(s); return NULL; }
    for (;;) {
        int c = accept(s, NULL, NULL);
        if (c < 0) continue;
        serve(c);
        close(c);
    }
    return NULL;
}

__attribute__((constructor))
static void reborn_start(void) {
    pthread_mutex_lock(&g_lock);
    profile_load(&g_prof);
    pthread_mutex_unlock(&g_lock);
    log_line("=== session start ===", 1, "");
    pthread_t t;
    pthread_create(&t, NULL, server_main, NULL);
    pthread_detach(t);
}
