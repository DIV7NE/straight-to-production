#!/usr/bin/env python3
"""STP Whiteboard Server — lightweight localhost server with live reload.

Usage: python3 serve.py [port] [project_dir]
  port:        defaults to 3333
  project_dir: defaults to current directory

Serves whiteboard/index.html and watches .stp/whiteboard-data.json
for changes. The HTML page polls /data.json every 2 seconds.
"""

import http.server
import json
import os
import sys
import shutil

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 3333
PROJECT_DIR = sys.argv[2] if len(sys.argv) > 2 else os.getcwd()

PLUGIN_DIR = os.path.dirname(os.path.abspath(__file__))
STP_DIR = os.path.join(PROJECT_DIR, '.stp')
DATA_FILE = os.path.join(STP_DIR, 'whiteboard-data.json')


class WhiteboardHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=PLUGIN_DIR, **kwargs)

    def do_GET(self):
        if self.path.startswith('/data.json'):
            self.serve_data()
            return
        if self.path == '/' or self.path == '/index.html':
            self.path = '/index.html'
            super().do_GET()
            return
        # Serve real files under the whiteboard plugin dir (e.g. codebase-map-template.html)
        requested = self.path.lstrip('/').split('?', 1)[0].split('#', 1)[0]
        if requested and os.path.isfile(os.path.join(PLUGIN_DIR, requested)):
            super().do_GET()
            return
        # Unknown path (e.g. /en from browser autocomplete) -> redirect to root
        # so stray URLs land on the whiteboard instead of a bare Python 404.
        self.send_response(302)
        self.send_header('Location', '/')
        self.end_headers()

    def serve_data(self):
        try:
            if os.path.exists(DATA_FILE):
                with open(DATA_FILE, 'r') as f:
                    data = f.read()
                self.send_response(200)
            else:
                data = json.dumps({
                    "status": "Waiting...",
                    "sections": []
                })
                self.send_response(200)

            self.send_header('Content-Type', 'application/json')
            self.send_header('Cache-Control', 'no-cache')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data.encode())
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())

    def log_message(self, format, *args):
        # Suppress request logging noise, only log errors
        if args and '404' in str(args[0]):
            super().log_message(format, *args)


def main():
    os.makedirs(STP_DIR, exist_ok=True)

    print(f"""
  ╔══════════════════════════════════════╗
  ║        STP Whiteboard Server         ║
  ╠══════════════════════════════════════╣
  ║                                      ║
  ║   http://localhost:{PORT:<17}  ║
  ║                                      ║
  ║   Watching: .stp/whiteboard-data     ║
  ║   Press Ctrl+C to stop               ║
  ║                                      ║
  ╚══════════════════════════════════════╝
""")

    with http.server.HTTPServer(('', PORT), WhiteboardHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('\nWhiteboard server stopped.')


if __name__ == '__main__':
    main()
