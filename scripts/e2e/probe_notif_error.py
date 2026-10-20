"""Catch the intermittent #/notifications page error with a real stack.

`walk_app.py` only logs `str(e)[:200]`, which for this error is the useless
"Error". This walks every route with a JS listener installed so the actual
error object is captured and printed.

Run: KHATA_ATTEMPTS=3 python scripts/e2e/probe_notif_error.py
"""
from __future__ import annotations

import os
import pathlib
import sys

for key in ("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy", "ALL_PROXY", "all_proxy"):
    os.environ.pop(key, None)
os.environ["NO_PROXY"] = "*"
os.environ["no_proxy"] = "*"

from playwright.sync_api import sync_playwright  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from walk_app import ROUTES, sign_in  # noqa: E402

URL = os.environ.get("KHATA_WEB", "http://127.0.0.1:8080")
ATTEMPTS = int(os.environ.get("KHATA_ATTEMPTS", "3"))

CAPTURE_JS = """
(() => {
  window.__errors = [];
  const keep = (e) => {
    // Flutter surfaces Dart errors as a JS Error whose message is the Dart
    // toString(); unhandled async errors come through unhandledrejection.
    const err = e.error || e.reason;
    window.__errors.push({
      kind: e.type,
      name: err && err.name ? err.name : typeof err,
      message: String(err && err.message !== undefined ? err.message : err),
      stack: err && err.stack ? String(err.stack) : '',
    });
  };
  window.addEventListener('error', keep);
  window.addEventListener('unhandledrejection', keep);
})();
"""


def one(playwright, index: int) -> None:
    browser = playwright.chromium.launch(channel="chrome", headless=True)
    context = browser.new_context(viewport={"width": 430, "height": 900})
    page = context.new_page()
    page.set_default_timeout(45_000)
    page.add_init_script(CAPTURE_JS)

    page.goto(URL, wait_until="load", timeout=90_000)
    page.wait_for_selector("flt-glass-pane", state="attached", timeout=90_000)
    page.wait_for_timeout(6000)
    if not sign_in(page):
        browser.close()
        print(f"[{index}] SIGN-IN FAILED", flush=True)
        return

    for name, route in ROUTES[1:]:
        page.goto(f"{URL}/{route}", wait_until="load", timeout=45_000)
        page.wait_for_timeout(2000)
        errors = page.evaluate("() => window.__errors || []")
        if errors:
            print(f"[{index}] {name} ({route}): {len(errors)} error(s)", flush=True)
            for err in errors[:3]:
                print(f"[{index}]   {err['kind']} {err['name']}: {err['message'][:300]}", flush=True)
                print(f"[{index}]   stack: {err['stack'][:700]}", flush=True)
            browser.close()
            return

    print(f"[{index}] no error captured across all {len(ROUTES)} routes", flush=True)
    browser.close()


def main() -> int:
    with sync_playwright() as playwright:
        for index in range(1, ATTEMPTS + 1):
            one(playwright, index)
    return 0


if __name__ == "__main__":
    sys.exit(main())
