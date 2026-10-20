"""Load the dashboard and wait for the numbers, not for a fixed delay.

Isolates one question: does the dashboard eventually render today's sales, or
is the mapping broken? The walk harness screenshots after 2.6s, which is less
than /api/reports/dashboard takes on a cold Supabase connection.
"""

from __future__ import annotations

import json
import os
import pathlib

for key in ("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy", "ALL_PROXY", "all_proxy"):
    os.environ.pop(key, None)
os.environ["NO_PROXY"] = "*"
os.environ["no_proxy"] = "*"

from playwright.sync_api import sync_playwright  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
SHOTS = HERE / "audit_shots"
URL = os.environ.get("KHATA_WEB", "http://127.0.0.1:8080")
account = json.loads((HERE / "demo_account.json").read_text(encoding="utf-8"))

NODES_JS = """
Array.from(document.querySelectorAll('flt-semantics')).map(n => {
  const r = n.getBoundingClientRect();
  return {label:(n.getAttribute('aria-label')||n.textContent||'').trim(),
          role:n.getAttribute('role')||'', hasInput:!!n.querySelector('input, textarea'),
          cx:Math.round(r.x+r.width/2), cy:Math.round(r.y+r.height/2),
          w:Math.round(r.width), h:Math.round(r.height)};
})
"""


def main() -> int:
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        context = browser.new_context(viewport={"width": 430, "height": 900})
        page = context.new_page()
        page.set_default_timeout(60_000)

        page.goto(URL, wait_until="load", timeout=90_000)
        page.wait_for_selector("flt-glass-pane", state="attached", timeout=90_000)
        page.wait_for_timeout(6000)

        # onboarding
        page.evaluate("() => { const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click(); }")
        page.wait_for_timeout(1200)
        nodes = page.evaluate(NODES_JS) or []
        skip = [n for n in nodes if n["role"] == "button" and n["label"].strip().lower() == "skip"]
        if skip:
            page.mouse.click(skip[0]["cx"], skip[0]["cy"])
            page.wait_for_timeout(2500)
        print("after onboarding:", page.url)

        # sign in
        page.evaluate("() => { const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click(); }")
        page.wait_for_timeout(1200)
        nodes = page.evaluate(NODES_JS) or []
        fields, seen = [], []
        for n in sorted([x for x in nodes if x["hasInput"] and 200 <= x["w"] <= 440 and 28 <= x["h"] <= 90],
                        key=lambda x: x["cy"]):
            if seen and abs(seen[-1] - n["cy"]) < 20:
                continue
            seen.append(n["cy"])
            fields.append(n)
        page.mouse.click(fields[0]["cx"], fields[0]["cy"])
        page.wait_for_timeout(300)
        page.keyboard.type(account["email"], delay=10)
        page.keyboard.press("Tab")
        page.wait_for_timeout(200)
        page.keyboard.type(account["password"], delay=10)
        buttons = [n for n in page.evaluate(NODES_JS) or []
                   if n["role"] == "button" and "sign" in n["label"].lower()]
        if buttons:
            page.mouse.click(buttons[0]["cx"], buttons[0]["cy"])
        else:
            page.keyboard.press("Enter")
        page.wait_for_timeout(5000)
        print("after sign-in:", page.url)

        page.screenshot(path=str(SHOTS / "dash-early.png"))
        for wait_ms in (3000, 4000, 4000):
            page.wait_for_timeout(wait_ms)
            labels = [n["label"] for n in (page.evaluate(NODES_JS) or []) if n["label"]]
            money = [x for x in labels if "Rs" in x or "रु" in x]
            print(f"after +{wait_ms}ms money labels: {money[:6]}")
        page.screenshot(path=str(SHOTS / "dash-settled.png"))
        browser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
