#!/usr/bin/env python3
"""
Subscription server for proxy configurations.
Serves Clash and v2rayN subscription files.
"""

import http.server
import os

SUB_TOKEN = os.environ.get("SUB_TOKEN", "")
SUB_PORT = int(os.environ.get("SUB_PORT", "2096"))


class Handler(http.server.SimpleHTTPRequestHandler):
    def _send_file(self, path, content_type, filename=None):
        try:
            size = os.path.getsize(path)
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(size))
            if filename:
                self.send_header("Content-Disposition", f"attachment; filename={filename}")
            self.end_headers()
            if self.command == "GET":
                with open(path, "rb") as f:
                    self.wfile.write(f.read())
        except FileNotFoundError:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        if self.path == f"/{SUB_TOKEN}/clash.yaml":
            self._send_file("/var/www/clash-sub.yaml", "text/yaml; charset=utf-8", "clash.yaml")
        elif self.path == f"/{SUB_TOKEN}/v2rayn.txt":
            self._send_file("/var/www/v2rayn-sub.txt", "text/plain; charset=utf-8")
        else:
            self.send_response(404)
            self.end_headers()

    def do_HEAD(self):
        self.do_GET()

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", SUB_PORT), Handler)
    server.serve_forever()
