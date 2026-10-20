"""Walk the Blazor admin console and record what breaks.

Real DOM (not canvas), so normal selectors work — this is the opposite of the
Flutter mobile app. Captures console errors, Blazor circuit failures and any
error banners the UI renders, plus a screenshot per page.
"""

from __future__ import annotations

import json
import os

for key in ("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy", "ALL_PROXY", "all_proxy"):
    os.environ.pop(key, None)
os.environ["NO_PROXY"] = "*"
os.environ["no_proxy"] = "*"

from playwright.sync_api import sync_playwright  # noqa: E402

URL = os.environ.get("KHATA_ADMIN", "http://localhost:5190")
SHOTS = "scripts/e2e/audit_shots"

ROUTES = [
    ("a-dashboard", "/"),
    ("a-users", "/users"),
    ("a-businesses", "/businesses"),
    ("a-tickets", "/tickets"),
    ("a-audit-logs", "/audit-logs"),
    ("a-feature-flags", "/feature-flags"),
]


def main() -> int:
    events: list[dict] = []

    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        context = browser.new_context(viewport={"width": 1440, "height": 900})
        page = context.new_page()
        page.set_default_timeout(60_000)

        page.on("console", lambda m: events.append(
            {"route": "login", "kind": f"console.{m.type}", "text": m.text[:250]})
            if m.type in ("error", "warning") else None)
        page.on("pageerror", lambda e: events.append(
            {"route": "login", "kind": "pageerror", "text": str(e)[:250]}))
        page.on("response", lambda r: events.append(
            {"route": "login", "kind": f"http.{r.status}", "text": r.url[:150]})
            if r.status >= 400 else None)

        page.goto(f"{URL}/login", wait_until="load", timeout=60_000)
        page.wait_for_timeout(2500)
        print("login page url:", page.url)

        page.fill("#email", "admin@khata.local")
        page.fill("#password", "Admin@12345")
        page.click("button[type=submit]")
        # Blazor needs a moment to establish the circuit after the redirect.
        page.wait_for_timeout(6000)
        print("after sign-in url:", page.url)
        page.screenshot(path=f"{SHOTS}/a-00-after-login.png")

        events.clear()

        for name, route in ROUTES:
            page.goto(f"{URL}{route}", wait_until="load", timeout=60_000)
            page.wait_for_timeout(4500)
            page.screenshot(path=f"{SHOTS}/{name}.png")

            body = page.inner_text("body")
            trouble = [w for w in ("unhandled exception", "reconnect", "error")
                       if w in body.lower()]
            before = len(events)
            print(f"{name:18} {page.url.replace(URL, ''):16} "
                  f"{'BROKEN:' + ','.join(trouble) if trouble else 'ok':28} "
                  f"{len(events) - before} net/console issue(s)")

        browser.close()

    print("\n=== issues ===")
    for e in events:
        print(f"  [{e['kind']}] {e['text']}")
    if not events:
        print("  none")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
