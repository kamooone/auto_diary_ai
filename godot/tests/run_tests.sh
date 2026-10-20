#!/bin/bash
# PointsClient の動作確認(偽サーバーを起動して、Godot をヘッドレスで実行する)
#   godot/tests/run_tests.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/points_test.XXXXXX")"
PORT=18765

mkdir -p "$WORK/project" "$WORK/home"
cp -R "$HERE/../auto_diary_points" "$WORK/project/"
cp "$HERE/test_points_client.gd" "$HERE/test_points_panel.gd" "$WORK/project/"
cat > "$WORK/project/project.godot" <<'PROJECT'
config_version=5

[application]
config/name="points_test"

[autoload]
Points="*res://auto_diary_points/points_client.gd"
PROJECT

python3 "$HERE/mock_server.py" "$PORT" &
SERVER=$!
trap 'kill $SERVER 2>/dev/null || true; rm -rf "$WORK"' EXIT
sleep 1

export HOME="$WORK/home" MOCK_URL="http://127.0.0.1:$PORT"
echo "== 部品(PointsClient)"
godot --headless --path "$WORK/project" -s res://test_points_client.gd

echo "== 画面(points_panel)"
godot --headless --path "$WORK/project" -s res://test_points_panel.gd
