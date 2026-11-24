# Reborn 로컬 서버 (3단계)

서비스 종료된 `fps.ss.nexon.com`을 대신해 게임의 HTTP 프로토콜을 흉내 내는
사설 서버. stdlib만 쓰므로 Python 3.8+ 외 설치물이 없다.

## 실행

```bash
# 기본: 0.0.0.0:80 (게임이 평문 HTTP 80번으로 접속하므로 80 권장)
sudo REBORN_PORT=80 python3 server/reborn_server.py
# 테스트용 고포트
REBORN_PORT=8080 python3 server/reborn_server.py
```

환경변수:
- `REBORN_PORT`(기본 80), `REBORN_BIND`(기본 0.0.0.0)
- `REBORN_URL` — `connection_string` 응답으로 돌려줄 주소. 비우면 클라이언트가
  접속해 온 Host를 그대로 돌려주므로, DNS 리다이렉트만으로 이후 요청도 전부 여기로 온다.

모든 요청은 콘솔과 `server/requests.log`에 해독된 봉투째 기록된다.

## 게임을 이 서버로 보내기 (DNS 리다이렉트)

서버 주소는 APK 안에 RSA로 암호화돼 있어 APK만으로는 바꾸기 어렵다. 가장 깔끔한
방법은 기기가 `fps.ss.nexon.com`을 이 서버 IP로 찾아가게 만드는 것이다.

- **루팅 기기**: `/system/etc/hosts`에 `서버IP  fps.ss.nexon.com` 추가
- **공유기/PC-DNS**: 로컬 DNS(dnsmasq, Pi-hole, AdGuard Home 등)에서
  `fps.ss.nexon.com` → 서버 IP로 응답하도록 설정하고, 기기 Wi-Fi DNS를 그 서버로 지정
- **에뮬레이터**: 호스트 PC의 hosts 파일 또는 에뮬레이터 네트워크 설정

최초 `connection_string` 요청만 이 리다이렉트로 들어오면, 응답의 `URL`로 이후
주소를 바꿀 수 있다(`REBORN_URL`). 다만 그 처리 경로가 디컴파일상 불확실하므로,
기본값(Host 에코)으로 두고 DNS 리다이렉트가 모든 요청을 받게 하는 쪽이 안전하다.

## 프로토콜

- 요청: `GET /game/<name>.php?a=<guid>&b=<payload>&c=1` 또는 같은 필드의 POST 폼
  - `b` = base64url( `M_WEB_REQUEST` JSON ), `=`·`+`·`/` 는 `%3D`·`%2B`·`%2F`
  - `M_WEB_REQUEST` = `{MD5,TIME,GUID,TOKEN,LANG,CODE,DATA,CB_NAME}`,
    `DATA`는 프로토콜별 인자가 담긴 JSON **문자열**
  - `MD5`는 위변조 검사용. 서버는 무시한다.
- 응답: 본문 = `M_WEB_RESPONSE` JSON `{CODE,RESULT,DATA,TIME,CB_NAME,ERROR}`
  - `RESULT`: 0=PASS(정상) 1=FAIL 2=SUCCESS, `DATA`는 JSON 문자열,
    `ERROR`는 정상 시 null, 실패 시 `M_ERROR{TYPE,NO,TKEY,MSG,PARAM,PROTOCOL}`
- 경로↔프로토콜 표: `analysis/obb_text/T_PROTOCOLS.json` (177개)

## 현재 구현 상태

봉투 해독/응답 골격과 `connection_string`, `login`, `create`, `myinfo`, `money`의
최소 응답이 들어 있다. 모르는 프로토콜은 빈 PASS 봉투로 응답하고 로그에 남겨, 클라이언트가
계속 진행하도록 한다. 각 응답의 `DATA` 필드 스키마(예: `myinfo`의 전체 유저 모델)는
실제 기기 로그를 보며 `HANDLERS`에 채워 나간다.

## 다음 작업

1. 기기를 DNS 리다이렉트로 이 서버에 붙이고, `connection_string`→`login`→`myinfo`→
   로비까지 요청 순서와 각 `DATA` 스키마를 `requests.log`로 수집.
2. 로그의 인자/콜백 기대값에 맞춰 각 핸들러의 응답을 채운다. 모델 클래스
   (`M_PLAYER`, `M_CONFIG`, 인벤토리 등)는 `analysis/il2cpp_dump/dump.cs`에서 필드 확인.
