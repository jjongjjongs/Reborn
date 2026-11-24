#!/usr/bin/env bash
# Produce an installable, updatable, release-signed APK with JDK tools only.
#
#   repack_sign.sh <in.apk> <out.apk> <keystore> <storepass> <alias>
#
# Steps: strip the original v1 signature, zipalign (pure-Python), then
# sign with jarsigner (APK v1 / JAR signing, accepted by Android for apps
# targeting SDK 28). Reusing the SAME keystore on every build is what lets a
# later versionCode install as an update instead of a conflicting app.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
IN="$1"; OUT="$2"; KS="$3"; SP="$4"; ALIAS="$5"
: "${JAVA_HOME:?set JAVA_HOME to a JDK}"
JS="$JAVA_HOME/bin/jarsigner"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

cp "$IN" "$TMP/unsigned.apk"
# 1. remove any existing signature so jarsigner writes a clean one
zip -qd "$TMP/unsigned.apk" 'META-INF/*.RSA' 'META-INF/*.SF' 'META-INF/*.DSA' 'META-INF/MANIFEST.MF' 2>/dev/null || true
# 2. align uncompressed entries (must happen before signing)
python3 -I "$HERE/zipalign.py" "$TMP/unsigned.apk" "$TMP/aligned.apk"
# 3. v1 sign
"$JS" -keystore "$KS" -storepass "$SP" -sigalg SHA256withRSA -digestalg SHA-256 \
      -signedjar "$OUT" "$TMP/aligned.apk" "$ALIAS"
# 4. verify
"$JS" -verify -verbose:summary "$OUT" | tail -2
echo "signed -> $OUT"
