# Special Soldier 분석 기록

## 대상

| 항목 | 값 |
|---|---|
| 패키지 | `com.wellgames.ss` 3.4.7 (빌드 347) |
| 엔진 | Unity 2018.3.0f2, IL2CPP, 메타데이터 v24.1 |
| Unity build-id | `6630b1da-14d9-46da-9643-67b04201d9f2` |
| APK SHA-256 | `9149aff943db720fb2e23eab5fb4a7485bfc56b48a32466bf8996242c35cc9c3` |
| `lib/arm64-v8a/libil2cpp.so` | `fee1ef4ec69a9cf00e1d12e53b5581ee34e17c542cb05e379c0a87f070686875` |
| `global-metadata.dat` | `1b810fddd9c933ce20dea9fd3d5384e496c1be4daed4acd982c3e0bc29254408` |

## 검은 화면 원인

### 1. OBB(확장 파일) 없음: 가장 유력

- APK에는 Unity 장면이 `level0` 하나뿐이다. 빌드 설정에는 `START`, `EMPTY`, `FPS`, `100`, `0`, `1`, `2` 장면이 등록돼 있다.
- `level0`은 PlayMaker FSM으로 `"LOADING..."`을 띄운 뒤 `LoadLevel("FPS")`를 호출하는 로더 장면이다. `FPS` 장면은 APK 안에 없다.
- Unity의 "Split Application Binary" 빌드라서 나머지 장면과 리소스는 `main.347.com.wellgames.ss.obb`에 들어 있다.
  - `libunity.so`에 `%s/main.%d.%s.obb` 문자열이 있다.
  - `classes.dex`에 `APKExpansionPolicy`가 있다.
- 따라서 OBB가 `/sdcard/Android/obb/com.wellgames.ss/main.347.com.wellgames.ss.obb`에 없으면 `FPS` 장면을 불러오지 못해 검은 화면에서 멈춘다.
- Unity는 OBB 안의 build-id가 APK와 같은지(`6630b1da-…`) 확인하므로, 같은 빌드의 OBB가 필요하다.

### 2. 서버 종료

OBB가 있더라도 다음 단계에서 `connection_string` 요청이 실패한다(아래 참고).

## 서버 통신 구조

### 서버 주소 (RSA로 암호화돼 있던 문자열을 복호화)

`Wellgames.Data.GIJBACLFCAD(name)`이 이름에 맞는 주소를 돌려준다.

| 이름 | 주소 |
|---|---|
| `DEFAULT` (실서버, `SetDefaultUrl(5)`) | `http://fps.ss.nexon.com` |
| `STAGE` | `http://fps.ss-stg.nexon.com` |
| `CHECK` | `http://fps.stg-beta.wgss.kr/` |
| `DEV` | `http://fps.dev.wgss.kr/` |
| `ENG` | `http://fps-en.wellgames.kr` |

`GetServerName()`은 주소에서 `http://fps.`를 지우고 `.` 앞부분을 쓴다(DEFAULT라면 `live`).

### 문자열 암호화

- 보호된 문자열 762개가 `<PrivateImplementationDetails>`의 바이트 배열로 들어 있다.
- 복호화 클래스는 `NLNPLGOEHOB`이다. 키는 1024비트 RSA PUBLICKEYBLOB(e = 17)이고, 128바이트 블록마다 `c^e mod n`을 계산한다.
- 복호화 도구는 `tools/il2cpp_v241/decrypt_strings.py`, 결과는 `il2cpp_dump/decrypted_strings.csv`이다.

### 요청 형식 (`HttpManager.PostProtocol` / `BPost`)

```
POST {서버 주소}{protocols[프로토콜 이름]}
  a = 사용자 GUID (int)
  b = Base64(UTF-8(요청 JSON)), '=' '+' '/'는 URL 이스케이프 (GLLPHABKNEO.GPKLIELPGMD)
  c = "1"
타임아웃 30초, 재시도 없음
```

요청 JSON은 `M_WEB_REQUEST`이다.

```json
{"MD5": "...", "TIME": "...", "GUID": 0, "TOKEN": 0, "LANG": "Korean", "CODE": "<프로토콜 이름>", "DATA": "<인자 JSON>", "CB_NAME": null}
```

- `MD5`: JSON 안의 자리표시자를 JSON 자체의 MD5(hex)로 바꾼 값(`GLLPHABKNEO.OCOEIBNMPBK`). 위변조 검사용이라 로컬 서버는 무시해도 된다.
- 프로토콜 이름을 경로로 바꾸는 표(`protocols`)는 `DataManager`의 TextAsset(JSON)에 있다. 이 파일은 APK에 없고 OBB 쪽에 있다.

### 응답 형식

- `BestHTTP`의 `DataAsText`를 그대로 콜백에 넘긴다(평문 JSON, `HttpListener.IsJson` 검사).
- `M_WEB_RESPONSE { CODE, RESULT, DATA, TIME, CB_NAME, ERROR }`로 파싱한다.
- 실패하면 `M_ERROR { TYPE, NO, TKEY, MSG, PARAM, PROTOCOL }`를 쓴다(`NOW_CANT_JOIN_TO_SERVER` 등).

### 시작 흐름

1. `U_Logo.PM_SetConnectionString`: 로딩 바를 표시하고 `SetDefaultUrl(5)`(DEFAULT)를 호출한다.
2. `connection_string` 프로토콜로 요청을 보낸다. 내용은 `CONNECTION_STRING_SEND_INFO { 연결 문자열 = hash("SPECIAL"+마켓+버전).ToString("x8"), 마켓, 버전, "NONE" }`이다.
3. 응답 `DATA`에 `URL`이 있으면 그 주소로 바꾼다. 이후 `GetServerName()`을 거쳐 `END_CONNECTION_STRING` 이벤트를 보낸다.
4. 이어서 `login`, `create`, `myinfo`, `inventory`, `shop_list` 순서로 진행한다(확인 필요).

헤더 없는 요청(`NonHeaderProtocol`)은 `GET {서버}/init/config.php?time=<난수>&MARKET=..&VERSION=..&DEPLOYMENT=NONE` 형식이다.

### 프로토콜 이름 (일부)

`connection_string, login, create, myinfo, money, inventory, pve_inventory, shop_list, shop_ver, equip, sell, upgrade, classup, disjoin, battle_result, mode_record, friend_list, friend_add, msg_list, msg_read, clan_*, party_*, gacha, gacha_info, attend, attend_list, mission_list, heartbeat, config_extend, update_option, tutorial_clear, debug_log ...`
(전체 목록: `HttpManager$$WWW_*`와 `xref_literals.py` 결과)

### 실시간 TCP (방·대전·채팅)

자체 프로토콜을 쓴다: `PACKET`, `SUB_PACKET`, `PACKET_CHAT*`, `FPS_TCP_ERROR`, `S_TCPADRESS`, `M_ROOM`, `ChatPacket`. 아직 분석하지 않았다.

### 보안·변조 검사 (APK를 수정할 때 주의)

- APK 서명 해시 검사: `AndroidUtils.HEELJOJFCBB`(`signatures`, `hashCode`, `APK_INVALID`)
- 루팅과 에뮬레이터(BlueStacks, Nox, MEmu, Andy) 감지, 치트 앱 감지
- 넥슨 NGSM 검증(`ngsm_verify`, `NPSN`, `NPACODE`, `SVCID`)

## 도구

| 도구 | 용도 |
|---|---|
| `tools/il2cpp_v241/il2cpp_dump.py` | 타입, 메서드, RVA, 문자열 리터럴 덤프 |
| `tools/il2cpp_v241/xref_literals.py` | 문자열을 읽는 메서드 찾기 |
| `tools/il2cpp_v241/callers.py` | 직접 호출(BL) 관계 |
| `tools/il2cpp_v241/decrypt_strings.py` | 난독화 문자열 복호화 |
| `tools/il2cpp_v241/ghidra_labels.py` | Ghidra용 이름 목록 생성 |
| `tools/ghidra/DecompileIl2cpp.java` | 헤드리스 Ghidra에 이름을 입히고 선택한 함수를 디컴파일 |
| `tools/ghidra/annotate_decrypted.py` | 디컴파일 결과에 복호화 문자열 주석 달기 |

Ghidra 사용법(자동 분석 없이 불러오기; 처음 한 번은 약 40분, 그다음부터는 몇 초):

```
analyzeHeadless <proj_dir> ss -import libil2cpp.so -noanalysis \
  -scriptPath tools/ghidra -postScript DecompileIl2cpp.java labels.tsv targets.txt out true
analyzeHeadless <proj_dir> ss -process libil2cpp.so -noanalysis \
  -scriptPath tools/ghidra -postScript DecompileIl2cpp.java labels.tsv targets.txt out false
```

Ghidra는 ELF를 0x100000에 올리므로, 디컴파일 결과의 `_DAT_xxxxxxxx` 주소는 RVA + 0x100000이다.
`decompiled/`에 지금까지 디컴파일한 함수가 있다.
