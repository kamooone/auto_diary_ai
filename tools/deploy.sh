#!/bin/bash
set -euo pipefail
set +x

cd "$(dirname "$0")/.."

PROJECT_ROOT="$(pwd)"
KEY_PROPERTIES="/Users/kondoukazusa/work/keys/auto_diary_ai/key.properties"
DEPLOYGATE_CREDENTIALS="$HOME/.config/deploygate/credentials"
OWNER="project-lka28"
AAB="$PROJECT_ROOT/build/app/outputs/bundle/release/app-release.aab"

# Required external credential files
if [ ! -r "$KEY_PROPERTIES" ]; then
    echo "ERROR: Android signing properties not found."
    exit 1
fi

if [ ! -r "$DEPLOYGATE_CREDENTIALS" ]; then
    echo "ERROR: DeployGate credentials not found."
    exit 1
fi

# Read Android signing properties without printing them.
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

if [ ! -r "$ANDROID_KEYSTORE_FILE" ]; then
    echo "ERROR: Android keystore not found."
    exit 1
fi

# Build a fresh release AAB.
rm -f "$AAB"

echo "Building release AAB..."
flutter build appbundle --release

if [ ! -f "$AAB" ]; then
    echo "ERROR: Release AAB was not generated."
    exit 1
fi

# Read DeployGate API token without printing it.
DEPLOYGATE_TOKEN="$(
    awk -F= '$1 == "api_token" {print substr($0, index($0,"=")+1); exit}' \
        "$DEPLOYGATE_CREDENTIALS"
)"

if [ -z "$DEPLOYGATE_TOKEN" ]; then
    echo "ERROR: DeployGate API token is missing."
    exit 1
fi

MESSAGE="${*:-auto_diary_ai release build}"

echo "Uploading AAB to DeployGate..."

RESPONSE="$(
    curl --fail-with-body --silent --show-error \
        --url "https://deploygate.com/api/users/${OWNER}/apps" \
        --header "Authorization: Bearer ${DEPLOYGATE_TOKEN}" \
        --request POST \
        --form "file=@${AAB}" \
        --form-string "message=${MESSAGE}"
)"

REVISION="$(
    printf '%s' "$RESPONSE" |
    python3 -c '
import json, sys
data = json.load(sys.stdin)
if data.get("error"):
    raise SystemExit(data.get("message", "DeployGate upload failed"))
print(data.get("results", {}).get("revision", "unknown"))
'
)"

echo "DeployGate upload completed."
echo "Revision: ${REVISION}"
echo "AAB: ${AAB}"
