# Special Soldier 분석 기록

## 대상

| 항목 | 값 |
|---|---|
| 패키지 | `com.wellgames.ss` 3.4.7 (빌드 347) |
| 엔진 | Unity 2018.3.0f2, IL2CPP, 메타데이터 v24.1 |
| APK SHA-256 | `9149aff943db720fb2e23eab5fb4a7485bfc56b48a32466bf8996242c35cc9c3` |
| `lib/arm64-v8a/libil2cpp.so` | `fee1ef4ec69a9cf00e1d12e53b5581ee34e17c542cb05e379c0a87f070686875` |
| `global-metadata.dat` | `1b810fddd9c933ce20dea9fd3d5384e496c1be4daed4acd982c3e0bc29254408` |

## 1단계: IL2CPP 이름 복원

REA(`rea-agents` 6.10.1)의 `inspect-il2cpp-metadata`는 Unity 2019.4 형식(헤더 264바이트)만
지원해서 이 파일(v24.1, 헤더 272바이트)을 거부한다. 그래서 `tools/il2cpp_v241/`에 전용 파서를 만들었다.

```
python3 tools/il2cpp_v241/il2cpp_dump.py <libil2cpp.so> <global-metadata.dat> <출력폴더>
python3 tools/il2cpp_v241/xref_literals.py <libil2cpp.so> <출력폴더> '<정규식>' ...
```

결과(`il2cpp_dump/`):

- `dump.cs`: 타입 9,675개의 필드(오프셋 포함)와 메서드(RVA 포함)
- `methods.csv`: 코드가 있는 메서드 64,959개의 RVA와 시그니처
- `string_literals.csv`: 문자열 리터럴 14,912개와 코드가 읽어 가는 슬롯 주소
- `ghidra_names.py`(저장소에는 없음, 덤프 시 생성): Ghidra에 함수와 문자열 슬롯 이름을 붙이는 스크립트

검증 결과, 메서드 주소 64,959개가 모두 `.text` 범위 안에 있다. `xref_literals.py`로
문자열을 쓰는 함수를 찾으면 `HttpManager$$GetServerName`처럼 맥락에 맞는 함수가 나온다.

## 서버 통신 구조 (확인된 것)

- **웹 API (HTTP, BestHTTP)**: `HttpManager`
  - `GetServerName()`에서 `"http://fps."`와 `"live"`로 서버 주소를 조립한다.
  - `BPost()`는 `?a={0}&b={1}&c={2}` 형식으로 요청을 보낸다.
  - 요청 본문은 `M_WEB_REQUEST { MD5, TIME, GUID, TOKEN, LANG, CODE, DATA, CB_NAME }`이다.
  - 응답은 `M_WEB_RESPONSE { CODE, RESULT, DATA, TIME, CB_NAME, ERROR }`이다.
  - 기능별 API: `WWW_Login`, `WWW_CreateAccount`, `WWW_Myinfo`, `WWW_MyInventory`, `WWW_ShopList`, `WWW_BattleResult` 등 100개 이상
  - 응답 오류 처리: `HttpListener$$CheckWWWError`("서버로 부터 데이터가 없습니다", `NOW_CANT_JOIN_TO_SERVER`)
- **실시간 TCP (방, 대전, 채팅)**: 자체 프로토콜
  - 관련 타입: `PACKET`, `SUB_PACKET`, `PACKET_CHAT*`, `FPS_TCP_ERROR`, `S_TCPADRESS`, `M_ROOM`, `ChatManager`, `ChatPacket`
- **고정 주소**: `http://fps.wellgames.kr/init/agree.php`, `/init/ncs.php`, `{0}/init/withdraw.php`, `http://ss-cdn.wellgames.kr`

## 다음 단계

1. `GetServerName`, `BPost`, `ToWebRequestJson`, `OnRequestFinished`를 디컴파일해서
   실제 URL, 파라미터 `a`·`b`·`c`, MD5 서명 방식, 응답 파싱 방식을 확정한다.
2. 시작 직후 호출 순서(로그인까지)를 따라가며 필요한 API 목록을 만든다.
3. 최소 응답을 돌려주는 로컬 서버를 만든다.
