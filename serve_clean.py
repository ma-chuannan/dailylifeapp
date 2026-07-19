#!/usr/bin/env python3
import http.server
import socketserver
import os
import time
import gzip
import io

PORT = 8080
os.chdir(r'D:\dailylifeapp\build\web')

# Text-like types where gzip yields meaningful size reduction.
# Skip binary (images, fonts, wasm) — already compressed, gzip would add CPU
# with little to no benefit, and WASM also wants its raw bytes for streaming
# compilation.
_GZIP_TYPES = {'.js', '.html', '.css', '.json', '.svg', '.txt', '.xml'}

# Bootstrap time used by both server and the bat to compute URL cache-busters.
# (The bat reads BOOT_TS via serve_clean.py? No - bat generates its own timestamp.
#  This value is just to make the no-store policy visible.)
BOOT_TS = int(time.time())

class H(http.server.SimpleHTTPRequestHandler):
    def send_head(self):
        """Override to add gzip compression for text-like resources when the
        client advertises Accept-Encoding: gzip. Falls back to super for
        directory listings, 404s, binary types, or clients without gzip."""
        path = self.translate_path(self.path)
        ext = os.path.splitext(path)[1].lower()
        accept_enc = (self.headers.get('Accept-Encoding') or '').lower()

        if ext in _GZIP_TYPES and 'gzip' in accept_enc and os.path.isfile(path):
            try:
                with open(path, 'rb') as f:
                    raw = f.read()
            except OSError:
                return super().send_head()
            gz = gzip.compress(raw, compresslevel=6)
            self.send_response(200)
            self.send_header('Content-Type', self.guess_type(path))
            self.send_header('Content-Encoding', 'gzip')
            self.send_header('Vary', 'Accept-Encoding')
            self.send_header('Content-Length', str(len(gz)))
            # Custom headers (same as end_headers below)
            self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
            self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
            self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
            self.send_header('Pragma', 'no-cache')
            self.send_header('Expires', '0')
            # No Clear-Site-Data here either (see end_headers comment).
            self.end_headers()
            return io.BytesIO(gz)
        return super().send_head()

    def end_headers(self):
        # 1. Required for SharedArrayBuffer (CanvasKit renderer)
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        # 2. Don't cache anything - prevents stale Service Worker / HTTP cache from
        #    serving a broken state after we update the build.
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        # NOTE: We deliberately do NOT send `Clear-Site-Data: "cache", "storage"`
        # because Chromium honors it on localhost too, which would wipe the
        # user's localStorage / IndexedDB on EVERY page load and destroy their
        # task data. The `Cache-Control: no-store` header above is enough to
        # prevent stale SW / HTTP cache from re-serving broken assets.
        super().end_headers()

    def log_message(self, fmt, *args):
        # Tee to a file we can read.
        try:
            with open(r'D:\dailylifeapp\serve.log', 'a', encoding='utf-8') as f:
                f.write('%s - - [%s] %s\n' % (self.address_string(), self.log_date_time_string(), fmt % args))
        except Exception:
            pass
        super().log_message(fmt, *args)

# Use ThreadingMixIn so concurrent requests (browser typically opens 6 connections)
# don't serialize behind the slow canvaskit.wasm transfer. Without this, the
# browser falls back to 1-connection-at-a-time on HTTP/1.1 and load time is
# dominated by the largest single resource (canvaskit.wasm = 5.7 MB).
class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

with ThreadingHTTPServer(("", PORT), H) as httpd:
    print(f"serve_clean.py BOOT_TS={BOOT_TS} (threading)")
    httpd.serve_forever()
