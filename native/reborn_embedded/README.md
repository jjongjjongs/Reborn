# 내장 서버 (단일 APK, PC·인터넷 불필요)

게임의 서버 역할을 **APK 안의 네이티브 서버**가 대신한다. PC도, Termux도,
인터넷도 필요 없고, 진행 상황도 폰 내부 저장소에 저장된다.

## 구성 요소

| 파일 | 역할 |
|---|---|
| `reborn_server.c` | 앱 프로세스 안에서 도는 작은 HTTP 서버. 로드 시 생성자(`__attribute__((constructor))`)가 자동 실행되어 `127.0.0.1:42427`에서 대기. 프로필을 `/data/data/com.wellgames.ss/files/reborn_profile.txt`에 읽고 씀. |
| `tools/build/patch_redirect.py` | `libil2cpp.so`의 `Wellgames.Data.GIJBACLFCAD`를 패치해 서버 주소를 `http://127.0.0.1:42427`로 바꿈(`il2cpp_string_new`로 문자열 생성·반환). |
| `tools/build/build_embedded.py` | OBB 병합 + 패치된 `libil2cpp.so` 교체 + `libreborn.so` 추가 + armeabi-v7a 제거 → 단일 APK. |
| `.github/workflows/embedded.yml` | CI에서 NDK로 `libreborn.so`(arm64) 컴파일 → 패치 → `patchelf --add-needed libreborn.so` → 조립 → 서명 → 릴리스. |

## 동작 원리

1. 앱이 켜지면 Unity가 `libil2cpp.so`를 로드 → 그 의존(DT_NEEDED)으로 걸어둔
   `libreborn.so`도 함께 로드 → 생성자가 서버 스레드를 띄움(127.0.0.1:42427).
2. 게임이 서버 주소를 만들 때 `GIJBACLFCAD`가 패치돼 있어 `127.0.0.1:42427`을 반환.
   모든 웹 요청이 폰 안 서버로 감.
3. 서버가 `connection_string/login/create/myinfo/money/...`에 응답하고, 변동은
   프로필 파일에 저장 → 재실행해도 유지.

## 범위와 한계

- 가능: 로그인 → 로비 → 상점/인벤토리 → PvE/봇/연습(클라이언트에서 도는 모드) + 저장.
- 불가: 실제 사람과의 실시간 PvP·방 매칭(별도 멀티 서버 필요, 종료됨).
- arm64-v8a 전용(최신 폰). 32비트 기기는 대상 외.

## 빌드

GitHub → Actions → **Embedded APK** → Run workflow.
결과물 `SpecialSoldier-reborn-3.4.7-embedded.apk`가 릴리스 `reborn-3.4.7`에 첨부된다.
이 APK **하나만** 설치하면 되고 OBB·서버·DNS 설정이 전부 불필요하다.

## 응답 채우기 (반복 작업)

처음에는 핵심 프로토콜만 구현돼 있다. 폰에서 돌려보며 막히는 화면이 있으면,
해당 프로토콜의 응답을 `reborn_server.c`의 `handle()`에 추가하고 워크플로를 다시 돌린다.
프로토콜↔응답 구조는 `analysis/README.md`, 모델 필드는 `analysis/il2cpp_dump/dump.cs` 참고.
