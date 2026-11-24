# 설치 파일 (Reborn 빌드 3.4.7 / versionCode 347)

재서명 APK와 그와 짝이 맞는 OBB. **반드시 쌍으로** 설치해야 서명 검사를 통과한다.

| 파일 | 설명 |
|---|---|
| `SpecialSoldier-reborn-3.4.7.apk` | Reborn 키로 재서명한 APK |
| `main.347.com.wellgames.ss.obb` | 서명 핀을 교체한 확장 파일 |

서명 키 인증서 해시 = `-1575741080` (APK·OBB 일치). 키스토어(개인 키)는 저장소에
포함하지 않는다 — 채팅으로 전달한 `reborn-release.keystore`를 보관할 것.

## 설치

1. 기존 앱 삭제
2. `SpecialSoldier-reborn-3.4.7.apk` 설치
3. `main.347.com.wellgames.ss.obb` 를 `/sdcard/Android/obb/com.wellgames.ss/` 에 복사

서버 주소는 아직 원본(`fps.ss.nexon.com`, 종료)이라, 접속 단계는 `server/`의 로컬
서버 + DNS 리다이렉트와 함께 써야 진행된다(`server/README.md`).
