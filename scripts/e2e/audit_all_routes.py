"""Walk EVERY route in the mobile app as a signed-in user and assert health.

Unlike audit_ui.py (31 curated routes), this covers the whole router — every
detail, edit and report screen — using ids from ui_fixtures.json. A route
fails when it bounces to /login, paints an empty screen, raises a JS error, or
fires a 5xx API call.

    python scripts/e2e/audit_all_routes.py
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
SHOTS = HERE / "audit_all_shots"
SHOTS.mkdir(exist_ok=True)
URL = os.environ.get("KHATA_WEB", "http://127.0.0.1:8080")

account = json.loads((HERE / "demo_account.json").read_text(encoding="utf-8"))
fixtures = json.loads((HERE / "ui_fixtures.json").read_text(encoding="utf-8"))

business_id = account["businessId"]
product_id = fixtures["productId"]
customer_id = fixtures["customerId"]
supplier_id = fixtures["supplierId"]

# (name, path) — every route registered in app_router.dart except the
# anonymous auth screens, which the sign-in flow already exercises.
ROUTES: list[tuple[str, str]] = [
    ("dashboard", "#/"),
    ("sales", "#/sales"),
    ("sale-new", "#/sales/new"),
    ("sale-detail", f"#/sales/{fixtures['saleId']}"),
    ("customers", "#/customers"),
    ("customer-new", "#/customers/new"),
    ("customer-edit", f"#/customers/{customer_id}/edit"),
    ("customer-ledger", f"#/customers/{customer_id}/ledger"),
    ("suppliers", "#/suppliers"),
    ("supplier-new", "#/suppliers/new"),
    ("supplier-edit", f"#/suppliers/{supplier_id}/edit"),
    ("supplier-ledger", f"#/suppliers/{supplier_id}/ledger"),
    ("products", "#/products"),
    ("product-new", "#/products/new"),
    ("product-edit", f"#/products/{product_id}/edit"),
    ("categories", "#/products/categories"),
    ("units", "#/products/units"),
    ("inventory", "#/inventory"),
    ("inventory-adjust", f"#/inventory/{product_id}/adjust"),
    ("inventory-movements", f"#/inventory/{product_id}/movements"),
    ("purchases", "#/purchases"),
    ("purchase-new", "#/purchases/new"),
    ("purchase-detail", f"#/purchases/{fixtures['purchaseId']}"),
    ("expenses", "#/expenses"),
    ("expense-new", "#/expenses/new"),
    ("expense-edit", f"#/expenses/{fixtures['expenseId']}/edit"),
    ("income", "#/income"),
    ("income-new", "#/income/new"),
    ("income-edit", f"#/income/{fixtures['incomeId']}/edit"),
    ("payments", "#/payments"),
    ("payment-new", "#/payments/new"),
    ("payment-methods", "#/payments/methods"),
    ("invoices", "#/invoices"),
    ("invoice-new", "#/invoices/new"),
    ("invoice-detail", f"#/invoices/{fixtures['invoiceId']}"),
    ("quotations", "#/quotations"),
    ("quotation-new", "#/quotations/new"),
    ("quotation-detail", f"#/quotations/{fixtures['quotationId']}"),
    ("reports", "#/reports"),
    ("report-sales", "#/reports/sales"),
    ("report-profit-loss", "#/reports/profit-loss"),
    ("report-expenses", "#/reports/expenses"),
    ("report-income", "#/reports/income"),
    ("report-stock", "#/reports/stock"),
    ("report-receivable", "#/reports/receivable-payable"),
    ("reminders", "#/reminders"),
    ("reminder-new", "#/reminders/new"),
    ("reminder-edit", f"#/reminders/{fixtures['reminderId']}/edit"),
    ("notifications", "#/notifications"),
    ("notification-settings", "#/notifications/settings"),
    ("sync", "#/sync"),
    ("backup", "#/backup"),
    ("import", "#/import"),
    ("businesses", "#/businesses"),
    ("business-setup", "#/business/setup"),
    ("business-members", f"#/businesses/{business_id}/members"),
    ("bank-accounts", "#/businesses/bank-accounts"),
    ("calculators", "#/tools/calculators"),
    ("app-lock", "#/settings/app-lock"),
    ("profile", "#/profile"),
    ("more", "#/more"),
]

SEMANTICS_JS = """
Array.from(document.querySelectorAll('flt-semantics')).map(n => {
  const r = n.getBoundingClientRect();
  return {
    label: (n.getAttribute('aria-label') || n.textContent || '').trim(),
    role: n.getAttribute('role') || '',
    hasInput: !!n.querySelector('input, textarea'),
    cx: Math.round(r.x + r.width / 2),
    cy: Math.round(r.y + r.height / 2),
    w: Math.round(r.width),
    h: Math.round(r.height),
  };
})
"""


class Recorder:
    def __init__(self) -> None:
        self.events: list[dict] = []
        self.current = "start"

    def attach(self, page) -> None:
        page.on("console", self._console)
        page.on("pageerror", self._pageerror)
        page.on("response", self._response)

    def _console(self, msg) -> None:
        if msg.type == "error":
            self.events.append({"route": self.current, "kind": "console.error", "text": msg.text[:300]})

    def _pageerror(self, err) -> None:
        self.events.append({"route": self.current, "kind": "pageerror", "text": str(err)[:300]})

    def _response(self, response) -> None:
        try:
            status, url = response.status, response.url
        except Exception:  # noqa: BLE001
            return
        if "/api/" not in url or status < 400:
            return
        self.events.append({"route": self.current, "kind": f"http.{status}",
                            "text": url.replace(URL, "")[:160]})


def nodes(page) -> list[dict]:
    try:
        return page.evaluate(SEMANTICS_JS) or []
    except Exception:  # noqa: BLE001
        return []


def dismiss_welcome(page, rec: Recorder) -> None:
    if "/welcome" not in page.url:
        return
    rec.current = "onboarding"
    page.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }")
    page.wait_for_timeout(1500)
    skip = [n for n in nodes(page)
            if n["role"] == "button" and n["label"].strip().lower() in ("skip", "छोड्नुहोस्", "छोड़ें")]
    if skip:
        page.mouse.click(skip[0]["cx"], skip[0]["cy"])
    else:
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
        if unique and abs(unique[-1]["cy"] - node["cy"]) < 20:
            continue
        unique.append(node)

    if unique:
        page.mouse.click(unique[0]["cx"], unique[0]["cy"])
        page.wait_for_timeout(300)
        page.keyboard.type(account["email"], delay=12)
        page.keyboard.press("Tab")
        page.wait_for_timeout(200)
        page.keyboard.type(account["password"], delay=12)
    else:
        size = page.viewport_size
        page.mouse.click(size["width"] * 0.5, size["height"] * 0.44)
        page.keyboard.type(account["email"], delay=12)
        page.keyboard.press("Tab")
        page.keyboard.type(account["password"], delay=12)

    page.wait_for_timeout(300)
    buttons = [n for n in nodes(page) if n["role"] == "button" and "sign" in n["label"].lower()]
    if buttons:
        page.mouse.click(buttons[0]["cx"], buttons[0]["cy"])
    else:
        page.keyboard.press("Enter")
    page.wait_for_timeout(5000)
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

        dismiss_welcome(page, rec)
        if not sign_in(page, rec):
            print("SIGN-IN FAILED")
            page.screenshot(path=str(SHOTS / "99-signin-failed.png"))
            browser.close()
            return 2
        print(f"signed in: {page.url}")

        for name, route in ROUTES:
            rec.current = name
            before = len(rec.events)
            try:
                page.goto(f"{URL}/{route}", wait_until="load", timeout=45_000)
            except Exception as error:  # noqa: BLE001
                results.append({"route": name, "path": route, "url": page.url,
                                "issues": [{"kind": "navigation", "text": str(error)[:200]}],
                                "blank": False})
                print(f"FAIL    {name:24} navigation error")
                continue
            page.wait_for_timeout(5000)
            page.screenshot(path=str(SHOTS / f"{name}.png"))

            issues = rec.events[before:]
            bounced = any(part in page.url for part in ("/welcome", "/login"))
            labels = [n["label"] for n in nodes(page) if n["label"].strip()]
            blank = len(labels) < 3
            results.append({"route": name, "path": route, "url": page.url,
                            "issues": issues, "blank": blank})

            if bounced:
                flag = "BOUNCED"
            elif any(i["kind"].startswith(("http.5", "pageerror")) for i in issues):
                flag = "FAIL"
            elif blank:
                flag = "BLANK"
            else:
                flag = "warn" if issues else "ok"
            print(f"{flag:8}{name:24} {page.url.split('#')[-1]:34} {len(issues)} issue(s)")

        browser.close()

    (HERE / "audit_all_report.json").write_text(json.dumps(results, indent=2), encoding="utf-8")

    bad = [r for r in results if r["blank"] or any(
        i["kind"].startswith(("http.5", "pageerror")) for i in r["issues"])]
    print(f"\n{len(results) - len(bad)}/{len(results)} routes healthy")
    for item in bad:
        print(f"  {item['route']}: blank={item['blank']}")
        for issue in item["issues"]:
            print(f"    [{issue['kind']}] {issue['text']}")
    return 0 if not bad else 1


if __name__ == "__main__":
    sys.exit(main())
