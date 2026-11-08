#!/bin/bash
# 単体テストをターミナルで実行する
#   tools/test.sh                      すべてのテスト
#   tools/test.sh test/core            指定したファイル・フォルダだけ
#   tools/test.sh -n '並行して取得'     名前に一致するテストだけ
set -euo pipefail

cd "$(dirname "$0")/.."

# pubspec.yamlでアセットに指定している.envは、Git管理外のため無いとテストを始められない
# (テストでは使わないため、無い場合は空のファイルを一時的に用意する)
if [ ! -e .env ]; then
    touch .env
    trap 'rm -f .env' EXIT
fi

flutter test "$@"
