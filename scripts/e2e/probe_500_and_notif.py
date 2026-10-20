"""Catch the two remaining intermitents with real evidence.

1. `console[error]: ... 500 (Internal Server Error)` seen once during sign-in —
   log every response with status >= 400 so the failing URL is named.
2. `PAGE ERROR: Error` on `#/notifications`, seen 3x in walks but 0x in
   focused runs — print the message, name and JS stack, not just "Error".

Run: KHATA_ATTEMPTS=2 python scripts/e2e/probe_500_and_notif.py
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
from walk_app import sign_in  # noqa: E402

URL = os.environ.get("KHATA_WEB", "http://127.0.0.1:8080")
ATTEMPTS = int(os.environ.get("KHATA_ATTEMPTS", "2"))

ROUTES = ["#/", "#/notifications", "#/reports", "#/dashboard"]


def one(playwright, index: int) -> None:
    browser = playwright.chromium.launch(channel="chrome", headless=True)
    context = browser.new_context(viewport={"width": 430, "height": 900})
    page = context.new_page()
    page.set_default_timeout(45_000)

    bad: list[str] = []

    def on_response(response) -> None:
        if response.status >= 400:
            bad.append(f"{response.status} {response.request.method} {response.url}")

    def on_pageerror(error) -> None:
        msg = str(error).strip()
        # Playwright's `str(error)` is the .message; dig for the real object.
        detail = page.evaluate(
            "() => window.__lastPageError ? String(window.__lastPageError) : 'not captured'"
        )
        print(f"  [{index}] PAGE ERROR message={msg[:200]!r}", flush=True)
        print(f"  [{index}]          detail={detail[:600]}", flush=True)

    page.on("response", on_response)
    page.on("pageerror", on_pageerror)
    page.add_init_script(
        "window.addEventListener('error', e => {"
        " window.__lastPageError = e.error || e.message; });"
        "window.addEventListener('unhandledrejection', e => {"
        " window.__lastPageError = e.reason; });"
    )

    print(f"[{index}] loading", flush=True)
    page.goto(URL, wait_until="load", timeout=90_000)
    page.wait_for_selector("flt-glass-pane", state="attached", timeout=90_000)
    page.wait_for_timeout(6000)
    if not sign_in(page):
        browser.close()
        print(f"[{index}] SIGN-IN FAILED", flush=True)
        return

    for route in ROUTES:
        page.goto(f"{URL}/{route}", wait_until="load", timeout=45_000)
        page.wait_for_timeout(2500)
        print(f"[{index}] {route}: {page.url}", flush=True)

    if bad:
        print(f"[{index}] *** {len(bad)} BAD RESPONSE(S) ***", flush=True)
        for b in bad:
            print(f"[{index}]   {b}", flush=True)
    else:
        print(f"[{index}] no 4xx/5xx responses", flush=True)
    browser.close()


def main() -> int:
    with sync_playwright() as playwright:
        for index in range(1, ATTEMPTS + 1):
            one(playwright, index)
    return 0


if __name__ == "__main__":
    sys.exit(main())
