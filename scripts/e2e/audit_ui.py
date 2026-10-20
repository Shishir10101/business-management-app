"""Walk every screen as a user would, and record what breaks.

Unlike walk_app.py (screenshots for eyeballing), this asserts: it collects
console errors, page errors and every non-2xx/3xx API response per route, then
prints a pass/fail table. A screen that paints but fires a 500 is a failure.

Run: python scripts/e2e/audit_ui.py
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
SHOTS = HERE / "audit_shots"
SHOTS.mkdir(exist_ok=True)
URL = os.environ.get("KHATA_WEB", "http://127.0.0.1:8080")
account = json.loads((HERE / "demo_account.json").read_text(encoding="utf-8"))

SEMANTICS_JS = """
Array.from(document.querySelectorAll('flt-semantics')).map(n => {
  const r = n.getBoundingClientRect();
  return {
    label: (n.getAttribute('aria-label') || n.textContent || '').trim().slice(0, 120),
    role: n.getAttribute('role') || '',
    hasInput: !!n.querySelector('input, textarea'),
    cx: Math.round(r.x + r.width / 2),
    cy: Math.round(r.y + r.height / 2),
    w: Math.round(r.width),
    h: Math.round(r.height),
  };
})
"""

ROUTES = [
    ("dashboard", "#/"),
    ("products", "#/products"),
    ("product-new", "#/products/new"),
    ("categories", "#/products/categories"),
    ("units", "#/products/units"),
    ("customers", "#/customers"),
    ("customer-new", "#/customers/new"),
    ("suppliers", "#/suppliers"),
    ("sales", "#/sales"),
    ("sale-detail", "#/sales/1"),
    ("sale-new", "#/sales/new"),
    ("purchases", "#/purchases"),
    ("payments", "#/payments"),
    ("expenses", "#/expenses"),
    ("incomes", "#/incomes"),
    ("invoices", "#/invoices"),
    ("invoice-detail", "#/invoices/1"),
    ("quotations", "#/quotations"),
    ("quotation-detail", "#/quotations/1"),
    ("reports", "#/reports"),
    ("inventory", "#/inventory"),
    ("reminders", "#/reminders"),
    ("notifications", "#/notifications"),
    ("sync", "#/sync"),
    ("backup", "#/backup"),
    ("import", "#/import"),
    ("bank-accounts", "#/businesses/bank-accounts"),
    ("calculators", "#/tools/calculators"),
    ("app-lock", "#/settings/app-lock"),
    ("profile", "#/profile"),
    ("more", "#/more"),
]


class Recorder:
    def __init__(self) -> None:
        self.events: list[dict] = []
        self.current = "start"

    def attach(self, page) -> None:
        page.on("console", self._console)
        page.on("pageerror", self._pageerror)
        page.on("response", self._response)

    def _console(self, msg) -> None:
        if msg.type in ("error", "warning"):
            self.events.append({"route": self.current, "kind": f"console.{msg.type}", "text": msg.text[:300]})

    def _pageerror(self, err) -> None:
        self.events.append({"route": self.current, "kind": "pageerror", "text": str(err)[:300]})

    def _response(self, response) -> None:
        try:
            status = response.status
            url = response.url
        except Exception:  # noqa: BLE001
            return
        if "/api/" not in url or status < 400:
            return
        self.events.append({
            "route": self.current,
            "kind": f"http.{status}",
            "text": url.replace(URL, "")[:160],
        })


def nodes(page) -> list[dict]:
    try:
        return page.evaluate(SEMANTICS_JS) or []
    except Exception:  # noqa: BLE001
        return []


def dismiss_welcome(page, rec: Recorder) -> None:
    """Get past the first-run tour.

    Until the `welcome_seen` flag is stored, the router redirects *every* route
    to /welcome — including /login — so a harness that skips this silently
    tests the onboarding screen 28 times and reports 28 passes.
    """
    if "/welcome" not in page.url:
        return
    rec.current = "onboarding"
    page.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }")
    page.wait_for_timeout(1500)

    skip = [
        n for n in nodes(page)
        if n["role"] == "button" and n["label"].strip().lower() in ("skip", "छोड्नुहोस्", "छोड़ें")
    ]
    if skip:
        page.mouse.click(skip[0]["cx"], skip[0]["cy"])
    else:
        # Skip sits bottom-left above the page indicator.
        size = page.viewport_size
        page.mouse.click(60, size["height"] - 90)
    page.wait_for_timeout(2500)


def sign_in(page, rec: Recorder) -> bool:
    rec.current = "login"
    page.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }")
    page.wait_for_timeout(1500)

    fields = [n for n in nodes(page) if n["hasInput"] and 200 <= n["w"] <= 440 and 28 <= n["h"] <= 90]
    unique: list[dict] = []
    for node in sorted(fields, key=lambda n: n["cy"]):
        # A field is reported twice (wrapper + input) with a few pixels between
        # them. An 8px tolerance left both in the list, so both clicks landed on
        # the email box and the second overwrote the first — the password ended
        # up in the email field.
        if unique and abs(unique[-1]["cy"] - node["cy"]) < 20:
            continue
        unique.append(node)
    print(f"  fields: {[(n['cx'], n['cy'], n['w'], n['h']) for n in unique]}")

    if unique:
        # Type into the first field, then Tab to the next one. Focus traversal is
        # how a person fills a form, and it cannot pick the same box twice.
        page.mouse.click(unique[0]["cx"], unique[0]["cy"])
        page.wait_for_timeout(300)
        page.keyboard.type(account["email"], delay=12)
        page.wait_for_timeout(200)
        page.keyboard.press("Tab")
        page.wait_for_timeout(200)
        page.keyboard.type(account["password"], delay=12)
    else:
        size = page.viewport_size
        page.mouse.click(size["width"] * 0.5, size["height"] * 0.44)
        page.wait_for_timeout(300)
        page.keyboard.type(account["email"], delay=12)
        page.keyboard.press("Tab")
        page.wait_for_timeout(200)
        page.keyboard.type(account["password"], delay=12)

    page.wait_for_timeout(300)
    page.screenshot(path=str(SHOTS / "00b-credentials.png"))

    buttons = [n for n in nodes(page) if n["role"] == "button" and "sign" in n["label"].lower()]
    if buttons:
        page.mouse.click(buttons[0]["cx"], buttons[0]["cy"])
    else:
        page.keyboard.press("Enter")

    page.wait_for_timeout(5000)
    # A URL of /welcome also satisfies "not on /login", which is how the first
    # version of this harness reported a successful sign-in while sitting on the
    # onboarding screen.
    return "login" not in page.url and "welcome" not in page.url


def main() -> int:
    rec = Recorder()
    results: list[dict] = []

    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        context = browser.new_context(viewport={"width": 430, "height": 900})
        page = context.new_page()
        page.set_default_timeout(45_000)
        rec.attach(page)

        page.goto(URL, wait_until="load", timeout=90_000)
        page.wait_for_selector("flt-glass-pane", state="attached", timeout=90_000)
        page.wait_for_timeout(7000)
        page.screenshot(path=str(SHOTS / "00-landing.png"))
        print(f"landing url: {page.url}")

        dismiss_welcome(page, rec)
        print(f"after onboarding: {page.url}")

        if not sign_in(page, rec):
            print("SIGN-IN FAILED — stopping")
            page.screenshot(path=str(SHOTS / "99-signin-failed.png"))
            browser.close()
            return 2
        print(f"signed in, url: {page.url}")

        for name, route in ROUTES:
            rec.current = name
            before = len(rec.events)
            page.goto(f"{URL}/{route}", wait_until="load", timeout=45_000)
            # /api/reports/dashboard takes 2.4-5.0s against Supabase Singapore.
            # At 2.6s the dashboard screenshot caught the pre-response state and
            # showed "Rs. 0.00", which reads as a data bug and is not one.
            page.wait_for_timeout(6000)
            page.screenshot(path=str(SHOTS / f"{name}.png"))
            issues = rec.events[before:]
            bounced = any(part in page.url for part in ("/welcome", "/login"))
            results.append({"route": name, "path": route, "url": page.url, "issues": issues, "bounced": bounced})
            if bounced:
                flag = "BOUNCED"
            elif any(i["kind"].startswith(("http.5", "pageerror")) for i in issues):
                flag = "FAIL"
            else:
                flag = "warn" if issues else "ok"
            print(f"{flag:7} {name:16} {page.url.split('#')[-1]:32} {len(issues)} issue(s)")

        browser.close()

    (HERE / "audit_report.json").write_text(json.dumps(results, indent=2), encoding="utf-8")

    print("\n=== issues ===")
    for item in results:
        for issue in item["issues"]:
            print(f"  [{issue['kind']}] {issue['route']}: {issue['text']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
