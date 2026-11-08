#!/bin/bash
# AABを作り、Google Playの内部テストにアップロードして公開する(下書きにしない)
#   tools/deploy_play.sh "リリースノート(実装内容を、ざっと)"
# 事前に、pubspec.yaml のビルド番号(+の後ろ)を、前回より大きくしておく
set -euo pipefail
set +x

cd "$(dirname "$0")/.."

export PLAY_SERVICE_ACCOUNT_FILE="/Users/kondoukazusa/keystores/play-service-account.json"
AAB="$(pwd)/build/app/outputs/bundle/release/app-release.aab"

if [ ! -r "$PLAY_SERVICE_ACCOUNT_FILE" ]; then
    echo "ERROR: Google Play service account JSON not found."
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "ERROR: リリースノートを引数で渡してください。"
    exit 1
fi

tools/build_aab.sh
python3 tools/play_upload.py "$AAB" "$*"
