# 릴리스 빌드 / 업데이트 설치 파이프라인

JDK 표준 도구(`keytool`, `jarsigner`)만 쓰는 재서명 파이프라인이다. Android
build-tools가 없어도 되도록 `zipalign`과 AXML 버전 패치는 Python으로 구현했다.

## 업데이트 설치가 되는 조건

Android가 "덮어쓰기 업데이트"로 인식하려면 세 가지가 모두 같아야/높아야 한다.

1. **패키지 이름** 동일 — `com.wellgames.ss` (그대로 둔다)
2. **서명 인증서** 동일 — 항상 같은 키스토어로 서명한다 (가장 중요)
3. **versionCode** 가 기존 설치본보다 크거나 같음

따라서 키스토어 하나를 만들어 **영구 보관**하고 모든 빌드에 재사용한다.
키스토어를 잃으면 이후 버전은 업데이트로 깔리지 않는다(기존 앱을 지워야 함).

## 키스토어 (한 번만)

```bash
keytool -genkeypair -v -keystore reborn-release.keystore \
  -storepass <PASS> -keypass <PASS> -alias reborn \
  -keyalg RSA -keysize 2048 -validity 18250 \
  -dname "CN=Reborn Revival, O=Reborn, C=NA"
```

이 세션에서 만든 키스토어(`reborn-release.keystore`, storepass/alias는 채팅으로 전달)는
사용자에게 파일로 보냈다. 안전하게 백업할 것. 이 저장소에는 **커밋하지 않는다**(개인 키).

## 빌드

```bash
export JAVA_HOME=/path/to/jdk            # JDK 17+ (jarsigner 포함)

# (선택) 다음 버전으로 올리기 — 업데이트 설치용
python3 tools/build/set_version.py input.apk 348 3.4.8

# 정렬 + 서명 + 검증
tools/build/repack_sign.sh input.apk reborn-348.apk reborn-release.keystore <PASS> reborn
```

- `set_version.py <apk> <versionCode> [versionName]`: 컴파일된 AndroidManifest.xml의
  두 속성만 수정한다. versionName은 기존 문자열보다 길면 안 된다(문자열 풀 고정 폭).
- `repack_sign.sh`: 기존 v1 서명 제거 → `zipalign.py` 정렬 → `jarsigner`로 v1 서명 →
  검증. 이 게임은 targetSdk 28이라 v1(JAR) 서명만으로 모든 기기에 설치된다.

## 주의: 앱 내부 서명 검사 (중요)

재서명하면 인증서가 바뀌므로, 앱이 시작 시 수행하는 **자체 서명 검사**에 걸린다.

- `JEFFHHLHJNB.DGACPNHKLHI`가 현재 APK 서명의 Java `Signature.hashCode()`를 계산해
  OBB의 `level2` 장면에 저장된 값 `-1916262714`와 비교한다.
- 불일치 시 `APK_INVALID` 팝업을 띄우고 진행을 막는다(`U_Title.View`,
  `AndroidUtils.EFCDONCOPAB`에서 호출).
- 루팅/에뮬레이터 감지와 넥슨 NGSM 검증도 별도로 있다.

즉 **재서명한 APK는 그대로는 타이틀에서 막힌다.** 실행되게 하려면 둘 중 하나가 필요하다.

- (A) OBB `level2`에 저장된 기대 해시를 우리 키의 `Signature.hashCode()` 값으로 교체
      (안티탬퍼를 제거하지 않고 핀만 우리 키로 바꾸는 방식)
- (B) `libil2cpp.so`의 해당 검사 함수를 통과하도록 패치

### 선택 1 적용 (OBB 핀 교체) — 완료

재서명 키의 인증서 해시가 11자(`-1916262714`와 같은 길이)가 되도록 키스토어를
생성해, OBB `level2`의 기대 해시를 그 값으로 그 자리에서 교체했다.

```bash
# 1) 11자 해시가 나오는 키스토어 찾기 (약 25% 확률, 보통 몇 번 안에 나옴)
#    tools/build 의 생성 루프 참고. 찾은 키스토어가 이후 영구 키스토어가 된다.
# 2) 그 키의 인증서 해시 계산 → NEW
# 3) OBB 의 기대 해시 교체 (OLD/NEW 길이 동일해야 함)
python3 tools/build/patch_obb_sig.py main.347.orig.obb main.347.com.wellgames.ss.obb -1916262714 <NEW>
# 4) 같은 키스토어로 APK 재서명
tools/build/repack_sign.sh in.apk out.apk reborn-release.keystore <PASS> reborn
```

현재 키스토어의 인증서 해시 = `-1575741080` (APK·OBB 양쪽 일치 확인).
루팅/에뮬레이터 감지와 NGSM은 별개이며, 실행 테스트에서 걸리면 그때 처리한다.
서버 주소를 우리 서버로 바꾸는 것은 다음 단계(3단계)다.
