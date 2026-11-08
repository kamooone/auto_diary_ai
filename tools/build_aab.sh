#!/bin/bash
# Google Play用の署名済みAABを作る(アップロードはしない)。引数なしで実行する
set -euo pipefail
set +x

cd "$(dirname "$0")/.."

KEY_PROPERTIES="/Users/kondoukazusa/work/keys/auto_diary_ai/key.properties"
AAB="$(pwd)/build/app/outputs/bundle/release/app-release.aab"

if [ ! -r "$KEY_PROPERTIES" ]; then
    echo "ERROR: Android signing properties not found."
    exit 1
fi

# 署名の情報は、画面に出さずに読み込む
while IFS='=' read -r key value; do
    case "$key" in
        storePassword) export ANDROID_KEYSTORE_PASSWORD="$value" ;;
        keyPassword)   export ANDROID_KEY_PASSWORD="$value" ;;
        keyAlias)      export ANDROID_KEY_ALIAS="$value" ;;
        storeFile)     export ANDROID_KEYSTORE_FILE="$value" ;;
    esac
done < "$KEY_PROPERTIES"

if [ -z "${ANDROID_KEYSTORE_PASSWORD:-}" ] ||
   [ -z "${ANDROID_KEY_PASSWORD:-}" ] ||
   [ -z "${ANDROID_KEY_ALIAS:-}" ] ||
   [ -z "${ANDROID_KEYSTORE_FILE:-}" ]; then
    echo "ERROR: Android signing properties are incomplete."
    exit 1
fi

rm -f "$AAB"
flutter build appbundle --release

if [ ! -f "$AAB" ]; then
    echo "ERROR: Release AAB was not generated."
    exit 1
fi

echo "AAB: ${AAB}"
