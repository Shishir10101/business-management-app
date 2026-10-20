"""Verify the RouteNotFoundScreen in a real browser.

Signs in, then drives three unmatched locations:
  * a mistyped deep link while signed in,
  * a path with a segment we never defined,
  * a deep link with no history at all (cold load on the bad hash),
and checks that the localized screen renders with a working recovery action.

Run: python scripts/e2e/probe_not_found.py
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
from walk_app import SHOTS, SEMANTICS_JS, enable_semantics, nodes, shot, sign_in  # noqa: E402

URL = os.environ.get("KHATA_WEB", "http://127.0.0.1:8080")

# Three shapes of "no route for this": signed in with a typo, a path whose
# first segment exists but the child does not, and a cold load straight onto
# the bad location (no history to pop back to).
CASES = [
    ("nf-warm-typo", "#/dashbord"),
    ("nf-warm-child", "#/products/not-a-thing"),
    ("nf-cold", None),
]


def expect_not_found(page, name: str) -> bool:
    labels = [n["label"] for n in nodes(page) if n["label"]]
    page_text = page.evaluate("() => document.body.innerText")
    ok_title = any("Page not found" in l or "पृष्ठ भेटिएन" in l for l in labels)
    ok_body = "not available" in page_text or "उपलब्ध छैन" in page_text
    # The raw GoException must never reach the screen.
    leak = "GoException" in page_text or "no routes for location" in page_text
    print(f"  [{name}] title={ok_title} body={ok_body} leaked_exception={leak}")
    return ok_title and ok_body and not leak


def main() -> int:
    failures = 0
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="chrome", headless=True)
        context = browser.new_context(viewport={"width": 430, "height": 900})
        page = context.new_page()
        page.set_default_timeout(45_000)
        page.on("pageerror", lambda e: print(f"  PAGE ERROR: {str(e)[:200]}"))

        # --- Warm cases: sign in first ---
        page.goto(URL, wait_until="load", timeout=90_000)
        page.wait_for_selector("flt-glass-pane", state="attached", timeout=90_000)
        page.wait_for_timeout(6000)
        if not sign_in(page):
            print("SIGN-IN FAILED")
            return 2

        for name, route in CASES[:2]:
            page.goto(f"{URL}/{route}", wait_until="load", timeout=45_000)
            page.wait_for_timeout(2500)
            shot(page, name)
            if not expect_not_found(page, name):
                failures += 1

        # Recovery: the primary action must land back on the dashboard.
        page.goto(f"{URL}/#/dashbord", wait_until="load", timeout=45_000)
        page.wait_for_timeout(2500)
        buttons = [
            n for n in nodes(page)
            if n["role"] == "button" and ("Dashboard" in n["label"] or "ड्यासबोर्ड" in n["label"])
        ]
        if buttons:
            page.mouse.click(buttons[0]["cx"], buttons[0]["cy"])
            page.wait_for_timeout(3500)
            shot(page, "nf-recovered")
            url = page.url
            dashboard = "Page not found" not in page.evaluate("() => document.body.innerText")
            print(f"  [nf-recovered] clicked Dashboard -> {url} (off error screen: {dashboard})")
            if not dashboard:
                failures += 1
        else:
            print("  [nf-recovered] no Dashboard recovery button found")
            failures += 1

        # --- Cold case: a *fresh* context, straight onto the bad hash. A
        # shared context would inherit the signed-in session (and silently
        # recover to the dashboard), which is not what a real cold load does.
        fresh = browser.new_context(viewport={"width": 430, "height": 900})
        cold = fresh.new_page()
        cold.on("pageerror", lambda e: print(f"  PAGE ERROR: {str(e)[:200]}"))
        cold.goto(f"{URL}/#/nope", wait_until="load", timeout=90_000)
        cold.wait_for_selector("flt-glass-pane", state="attached", timeout=90_000)
        cold.wait_for_timeout(8000)
        enable_semantics(cold)
        cold.wait_for_timeout(1500)
        shot(cold, "nf-cold")
        cold_labels = [n["label"] for n in nodes(cold) if n["label"]]
        cold_text = cold.evaluate("() => document.body.innerText")
        cold_ok = any("Page not found" in l for l in cold_labels)
        cold_leak = "GoException" in cold_text
        # Unauthenticated + unknown location: the auth redirect owns the screen.
        login = "Sign In" in cold_text or "Sign In" in " ".join(cold_labels)
        print(f"  [nf-cold] not_found={cold_ok} login_redirect={login} leaked={cold_leak} url={cold.url}")
        if cold_leak:
            failures += 1

        browser.close()

    print(f"FAILURES: {failures}")
    print(f"screenshots in {SHOTS}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
