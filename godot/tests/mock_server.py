#!/usr/bin/env python3
"""Godotの部品を試すための、偽のポイントサーバー(本物のAPIと同じ形で答える)

  python3 godot/tests/mock_server.py 8765
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

KEY = "test-key"
TOKEN = "dev1.secret"

state = {"claims": 0, "events": [], "link_after": 2, "fail_next_event": 0, "revoked": False}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        path = self.path

        if path == "/_state":
            state.update(body)
            return self.reply(200, state)

        if path == "/pairing/start":
            if self.headers.get("X-App-Key") != KEY:
                return self.reply(403, {"error": "invalid_app"})
            return self.reply(200, {"code": "123456", "claimSecret": "s", "expiresAt": 4102444800})

        if path == "/pairing/claim":
            state["claims"] += 1
            if state["claims"] < state["link_after"]:
                return self.reply(202, {"status": "pending"})
            return self.reply(200, {"status": "linked", "deviceToken": TOKEN})

        if path == "/device/unlink":
            if self.headers.get("X-Device-Token") != TOKEN:
                return self.reply(401, {"error": "invalid_device_token"})
            state["unlinked"] = state.get("unlinked", 0) + 1
            return self.reply(200, {"unlinked": True})

        if path == "/events":
            if self.headers.get("X-App-Key") != KEY:
                return self.reply(401, {"error": "invalid_app"})
            if state["revoked"] or self.headers.get("X-Device-Token") != TOKEN:
                return self.reply(401, {"error": "invalid_device_token"})
            if state["fail_next_event"] > 0:
                state["fail_next_event"] -= 1
                return self.reply(503, {})
            state["events"].append(body)
            if body["type"] == "limited_event" and sum(
                1 for e in state["events"] if e["type"] == "limited_event"
            ) > 1:
                return self.reply(200, {"granted": 0, "reason": "event_limit"})
            return self.reply(200, {"granted": 50, "points": 50 * len(state["events"])})

        self.reply(404, {})

    def do_GET(self):
        self.reply(200, state)


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
