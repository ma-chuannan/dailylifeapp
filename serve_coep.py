#!/usr/bin/env python3
"""Serve build/web with COOP/COEP headers for Flutter CanvasKit chromium variant."""
import http.server
import socketserver
import os

PORT = 8080
os.chdir(r'D:\dailylifeapp\build\web')

class COEPHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Required for crossOriginIsolated = true
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Resource-Policy', 'cross-origin')
        # Cache control to ensure no stale
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

with socketserver.TCPServer(("", PORT), COEPHandler) as httpd:
    print(f"Serving with COOP/COEP at http://localhost:{PORT}")
    httpd.serve_forever()
