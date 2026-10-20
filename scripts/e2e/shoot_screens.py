"""Screenshot the refreshed dashboard and list screens."""
import json

from playwright.sync_api import sync_playwright

URL = "http://127.0.0.1:8080/"
SHOTS = "E:/business-management-app/docs/screenshots"
CREDS = json.load(open("E:/business-management-app/scripts/e2e/demo_account.json"))

JS = """
() => Array.from(document.querySelectorAll('flt-semantics')).map(n => {
  const r = n.getBoundingClientRect();
  return {label: (n.getAttribute('aria-label') || n.textContent || '').trim(),
          role: n.getAttribute('role') || '',
          hasInput: !!n.querySelector('input, textarea'),
          cx: Math.round(r.x + r.width/2), cy: Math.round(r.y + r.height/2),
          w: Math.round(r.width), h: Math.round(r.height)};
}).filter(n => n.w > 0 && n.h > 0)
"""


def nodes(page):
    return page.evaluate(JS)


with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", headless=True)
    page = b.new_page(viewport={"width": 420, "height": 880})
    page.goto(URL, wait_until="load", timeout=90000)
    page.wait_for_selector("flt-glass-pane", state="attached", timeout=90000)
    page.wait_for_timeout(7000)
    page.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }")
    page.wait_for_timeout(1200)

    fields = sorted([n for n in nodes(page) if n["hasInput"] and 28 <= n["h"] <= 80 and n["w"] >= 100],
                    key=lambda n: n["cy"])
    for f, text in zip(fields, [CREDS["email"], CREDS["password"]]):
        page.mouse.click(f["cx"], f["cy"])
        page.wait_for_timeout(350)
        page.keyboard.type(text, delay=20)
    btn = next((n for n in nodes(page) if n["role"] == "button" and n["label"].strip() in ("Sign In", "साइन इन गर्नुहोस्")), None)
    if btn:
        page.mouse.click(btn["cx"], btn["cy"])
    page.wait_for_timeout(10000)

    page.screenshot(path=f"{SHOTS}/ux-01-home.png")
    print("home:", page.url)

    for path, name in [
        ("#/products", "ux-02-products"),
        ("#/customers", "ux-03-customers"),
        ("#/reports", "ux-04-reports"),
        ("#/sales/new", "ux-05-sale-form"),
    ]:
        page.goto(URL + path, wait_until="load")
        page.wait_for_timeout(5000)
        page.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }")
        page.wait_for_timeout(1000)
        page.screenshot(path=f"{SHOTS}/{name}.png")
        print(name, page.url)

    b.close()
