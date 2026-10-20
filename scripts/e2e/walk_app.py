"""Drive the built web app in real Chrome and capture every screen.

Signs in with the account created by seed_demo_account.py, walks the routes by
hash, and writes screenshots + a log. It does not assert much: the point is
evidence to look at, and a record of what each screen did.

Run: python scripts/e2e/walk_app.py
"""

from __future__ import annotations

import json
import os
import pathlib
import sys

for key in ("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy", "ALL_PROXY", "all_proxy"):
    os.environ.pop(key, None)
os.environ["NO_PROXY"] = "*"
os.environ["no_proxy"] = "*"

from playwright.sync_api import sync_playwright  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
SHOTS = HERE / "shots"
SHOTS.mkdir(exist_ok=True)
LOG = HERE / "walk.log"

URL = os.environ.get("KHATA_WEB", "http://127.0.0.1:8080")
account = json.loads((HERE / "demo_account.json").read_text(encoding="utf-8"))

lines: list[str] = []


def log(message: str) -> None:
    lines.append(message)
    print(message, flush=True)


SEMANTICS_JS = """
Array.from(document.querySelectorAll('flt-semantics')).map(n => {
  const r = n.getBoundingClientRect();
  return {
    label: (n.getAttribute('aria-label') || n.textContent || '').trim().slice(0, 80),
    role: n.getAttribute('role') || '',
    hasInput: !!n.querySelector('input, textarea'),
    cx: Math.round(r.x + r.width / 2),
    cy: Math.round(r.y + r.height / 2),
    w: Math.round(r.width),
    h: Math.round(r.height),
  };
})
"""


def enable_semantics(page) -> None:
    try:
        page.evaluate(
            "() => { const p = document.querySelector('flt-semantics-placeholder');"
            " if (p) p.click(); }"
        )
        page.wait_for_timeout(1200)
    except Exception as error:  # noqa: BLE001
        log(f"  semantics placeholder: {error}")


def nodes(page) -> list[dict]:
    try:
        return page.evaluate(SEMANTICS_JS) or []
    except Exception:  # noqa: BLE001
        return []


def shot(page, name: str) -> None:
    page.screenshot(path=str(SHOTS / f"{name}.png"))


def sign_in(page) -> bool:
    log("sign-in: enabling semantics")
    enable_semantics(page)

    found = [
        n for n in nodes(page)
        if n["hasInput"] and 300 <= n["w"] <= 410 and n["h"] >= 30
    ]
    # Some fields are reported twice (wrapper + input); keep one per row.
    unique: list[dict] = []
    for node in sorted(found, key=lambda n: n["cy"]):
        if unique and abs(unique[-1]["cy"] - node["cy"]) < 8:
            continue
        unique.append(node)
    found = unique
    log(f"  text fields: {[(n['cx'], n['cy'], n['w']) for n in found]}")

    if len(found) >= 2:
        for node, value in zip(found[:2], [account["email"], account["password"]]):
            page.mouse.click(node["cx"], node["cy"])
            page.wait_for_timeout(250)
            page.keyboard.press("Control+A")
            page.keyboard.press("Backspace")
            page.keyboard.type(value, delay=12)
            page.wait_for_timeout(150)
    else:
        # Fallback: the login form's two fields sit in the middle of the card.
        size = page.viewport_size
        for fraction, value in ((0.44, account["email"]), (0.53, account["password"])):
            page.mouse.click(size["width"] * 0.5, size["height"] * fraction)
            page.wait_for_timeout(250)
            page.keyboard.type(value, delay=12)
            page.wait_for_timeout(150)

    shot(page, "00-credentials-typed")

    buttons = [
        n for n in nodes(page)
        if n["role"] == "button" and "sign" in n["label"].lower()
    ]
    if buttons:
        page.mouse.click(buttons[0]["cx"], buttons[0]["cy"])
        log(f"  clicked button {buttons[0]['label']!r}")
    else:
        page.keyboard.press("Enter")
        log("  pressed Enter (no Sign In button in the semantics tree)")

    page.wait_for_timeout(4000)
    log(f"  url after sign-in: {page.url}")
    return "login" not in page.url


ROUTES = [
    ("01-dashboard", "#/"),
    ("02-products", "#/products"),
    ("03-customers", "#/customers"),
    ("04-suppliers", "#/suppliers"),
    ("05-sales", "#/sales"),
    ("06-sale-new", "#/sales/new"),
    ("07-import", "#/import"),
    ("08-reports", "#/reports"),
    ("09-payments", "#/payments"),
    ("10-inventory", "#/inventory"),
    ("11-reminders", "#/reminders"),
    ("12-notifications", "#/notifications"),
    ("13-sync", "#/sync"),
    ("14-backup", "#/backup"),
    ("15-bank-accounts", "#/businesses/bank-accounts"),
    ("16-calculators", "#/tools/calculators"),
    ("17-app-lock", "#/settings/app-lock"),
    ("18-profile", "#/profile"),
]


def main() -> int:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel="chrome", headless=True)
        context = browser.new_context(viewport={"width": 430, "height": 900})
        page = context.new_page()
        page.set_default_timeout(45_000)

        page.on("console", lambda m: log(f"  console[{m.type}]: {m.text[:160]}")
                if m.type in ("error", "warning") else None)
        page.on("pageerror", lambda e: log(f"  PAGE ERROR: {str(e)[:200]}"))

        log(f"loading {URL}")
        page.goto(URL, wait_until="load", timeout=90_000)
        page.wait_for_selector("flt-glass-pane", state="attached", timeout=90_000)
        page.wait_for_timeout(7000)
        shot(page, "00-first-paint")
        log(f"  url: {page.url}")

        if not sign_in(page):
            log("SIGN-IN FAILED — stopping")
            shot(page, "99-signin-failed")
            (HERE / "walk.log").write_text("\n".join(lines), encoding="utf-8")
            browser.close()
            return 2

        shot(page, "01-dashboard")

        for name, route in ROUTES[1:]:
            page.goto(f"{URL}/{route}", wait_until="load", timeout=45_000)
            page.wait_for_timeout(2500)
            shot(page, name)
            log(f"{name}: {page.url}")

        browser.close()

    (HERE / "walk.log").write_text("\n".join(lines), encoding="utf-8")
    log(f"screenshots in {SHOTS}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
