"""Serve the built APK to a phone on the same Wi-Fi.

`python -m http.server` sends `.apk` as `application/octet-stream`, which some
Android browsers then save with a `.bin` name. This sends the real package MIME
type plus a `Content-Disposition` filename, so tapping the link downloads
`khata-demo-0.1.0.apk` and the installer opens on the tap.

Usage:
    python scripts/serve_apk.py            # port 8090, serves dist/
    python scripts/serve_apk.py 9000
"""
from __future__ import annotations

import http.server
import os
import pathlib
import socket
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / "dist"
APK_NAME = "khata-demo-0.1.0.apk"
APK_MIME = "application/vnd.android.package-archive"


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def guess_type(self, path):  # noqa: A003 - stdlib signature
        if str(path).endswith(".apk"):
            return APK_MIME
        return super().guess_type(path)

    def end_headers(self):
        # Chrome refuses to hand an APK to the installer when the server says
        # `text/plain` or when a stale page is served from cache.
        if self.path.split("?")[0].endswith(".apk"):
            self.send_header("Content-Disposition", f'attachment; filename="{APK_NAME}"')
            self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, fmt, *args):  # keep the console readable
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))


def lan_ip() -> str:
    """The address a phone on the same network can reach (not 127.0.0.1)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("192.168.18.18", 80))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def main() -> None:
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8090
    if not (ROOT / APK_NAME).exists():
        sys.exit(f"missing {ROOT / APK_NAME} — build it first")
    os.chdir(ROOT)
    print(f"serving {ROOT} on http://{lan_ip()}:{port}/", flush=True)
    http.server.ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()


if __name__ == "__main__":
    main()
