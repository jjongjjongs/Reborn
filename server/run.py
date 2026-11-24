#!/usr/bin/env python3
"""One-command launcher: DNS redirector + Reborn HTTP server together.

Run this on a PC on the same Wi-Fi as the phone, then set the phone's Wi-Fi
DNS to this PC. Needs root (ports 53 + 80). Pure stdlib.

  sudo python3 server/run.py

Env (optional): REBORN_IP, DNS_UPSTREAM, REBORN_URL, REBORN_PORT, DNS_PORT.
"""
import os
import socket
import sys
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)


def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect((os.environ.get("DNS_UPSTREAM", "8.8.8.8"), 53))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def main():
    ip = os.environ.get("REBORN_IP") or lan_ip()
    os.environ.setdefault("REBORN_IP", ip)
    import dns_redirect
    import reborn_server

    print("=" * 60)
    print("  Reborn server + DNS redirector")
    print("=" * 60)
    print(f"  이 PC의 LAN IP : {ip}")
    print(f"  폰에서 할 일   : Wi-Fi 설정 > 현재 네트워크 > IP 설정을 '고정'으로")
    print(f"                   DNS 1 = {ip}  (DNS 2 는 비우거나 {ip})")
    print(f"  그 다음 게임 실행. 로그는 아래에 흐르고 server/requests.log 에도 쌓임.")
    print("=" * 60)

    t = threading.Thread(target=dns_redirect.main, daemon=True)
    t.start()
    try:
        reborn_server.main()  # blocks (serves HTTP on :80)
    except PermissionError:
        sys.exit("포트 53/80 바인딩에 root 권한이 필요합니다: sudo python3 server/run.py")


if __name__ == "__main__":
    main()
