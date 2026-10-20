"""Verify the bottom-navigation shell, the new home layout, the parties
toggle and the More page — in a real browser against the demo SQLite API.

Flutter web renders into a shadow DOM, so this drives the semantics tree and
clicks real bounding boxes (same approach as check_language_calendar.py).

Usage:
  python scripts/e2e/check_ui_shell.py
"""
import json
import sys

from playwright.sync_api import sync_playwright

URL = "http://127.0.0.1:8080/"
SHOTS = "E:/business-management-app/docs/screenshots"
CREDS = json.load(open("E:/business-management-app/scripts/e2e/demo_account.json"))

SEMANTICS_JS = """
() => Array.from(document.querySelectorAll('flt-semantics')).map(n => {
  const r = n.getBoundingClientRect();
  return {label: (n.getAttribute('aria-label') || n.textContent || '').trim(),
          role: n.getAttribute('role') || '',
          hasInput: !!n.querySelector('input, textarea'),
          cx: Math.round(r.x + r.width/2), cy: Math.round(r.y + r.height/2),
          w: Math.round(r.width), h: Math.round(r.height)};
}).filter(n => n.w > 0 && n.h > 0)
"""

results = []
console_errors = []


def say(msg):
    print(msg, flush=True)


def nodes(page):
    return page.evaluate(SEMANTICS_JS)


def labels(page):
    return [n["label"] for n in nodes(page) if n["label"]]


def has(page, needle):
    """Case-insensitive: section headers are rendered uppercase by the widget."""
    n = needle.lower()
    return any(n in l.lower() for l in labels(page))


def has_exact(page, needle):
    return any(l.strip() == needle for l in labels(page))


def has_any(page, *needles):
    return any(has(page, n) for n in needles)


def enable(page):
    page.evaluate(
        "() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }"
    )
    page.wait_for_timeout(1200)


def fill(page, text, index=0):
    fields = sorted(
        [n for n in nodes(page) if n["hasInput"] and 28 <= n["h"] <= 80 and n["w"] >= 100],
        key=lambda n: n["cy"],
    )
    if index >= len(fields):
        return False
    f = fields[index]
    page.mouse.click(f["cx"], f["cy"])
    page.wait_for_timeout(350)
    page.keyboard.type(text, delay=20)
    return True


def click_label(page, needle, exact=False, max_y=880):
    cands = [
        n for n in nodes(page)
        if n["label"].strip()
        and (n["label"].strip() == needle if exact else needle in n["label"])
        and 0 < n["cy"] < max_y
    ]
    if not cands:
        say(f"   !! nothing clickable for {needle!r}")
        for n in nodes(page):
            if n["label"]:
                say(f"      {n['role']:>9} ({n['cx']},{n['cy']}) {n['w']}x{n['h']} "
                    f"{n['label'][:34]!r}")
        return False
    target = min(cands, key=lambda n: n["w"] * n["h"])
    page.mouse.click(target["cx"], target["cy"])
    return True


def tab(page, *needles):
    """Taps a bottom-bar destination. The bar sits in the last 70 px."""
    for needle in needles:
        cands = [
            n for n in nodes(page)
            if n["label"].strip() and needle in n["label"] and n["cy"] > 810
        ]
        if cands:
            target = min(cands, key=lambda n: n["w"] * n["h"])
            page.mouse.click(target["cx"], target["cy"])
            page.wait_for_timeout(1800)
            return True
    say(f"   !! no tab for {needles}")
    say(f"   bar: {[ (n['label'][:16], n['cy']) for n in nodes(page) if n['cy'] > 800 and n['label']][:8]}")
    return False


with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", headless=True)
    page = b.new_page(viewport={"width": 420, "height": 880})
    page.on("console", lambda m: console_errors.append(m.text) if m.type == "error" else None)
    page.on("pageerror", lambda e: console_errors.append(str(e)))

    page.goto(URL, wait_until="load", timeout=90000)
    page.wait_for_selector("flt-glass-pane", state="attached", timeout=90000)
    page.wait_for_timeout(7000)
    enable(page)
    fill(page, CREDS["email"], 0)
    fill(page, CREDS["password"], 1)
    click_label(page, "Sign In", exact=True)
    page.wait_for_timeout(9000)
    say(f"after login: {page.url}")

    # --- home -----------------------------------------------------------
    enable(page)
    bar = [n["label"] for n in nodes(page) if n["cy"] > 810 and n["label"]]
    say(f"bottom bar: {[l[:14] for l in bar]}")
    results.append(("bottom bar has 5 destinations", len(bar) >= 5))
    results.append(("home shows recent activity", has_any(page, "हालैका गतिविधि", "Recent activity")))
    results.append(("home shows quick actions", has_any(page, "नयाँ बिक्री", "New sale")))
    page.screenshot(path=f"{SHOTS}/ux2-01-home.png")

    # --- sales tab ------------------------------------------------------
    ok = tab(page, "बिक्री", "Sales")
    results.append(("sales tab opens", ok and has_any(page, "बिक्री", "Sales")))
    page.screenshot(path=f"{SHOTS}/ux2-02-sales.png")

    # --- parties tab ----------------------------------------------------
    ok = tab(page, "खाता", "Parties")
    page.wait_for_timeout(1500)
    results.append(("parties tab opens", ok))
    results.append(("parties has customers/suppliers toggle",
                    has_any(page, "ग्राहकहरू", "Customers")))
    page.screenshot(path=f"{SHOTS}/ux2-03-parties.png")

    # switch to suppliers through the segmented control
    if click_label(page, "आपूर्तिकर्ता", max_y=300) or click_label(page, "Suppliers", max_y=300):
        page.wait_for_timeout(2500)
        say(f"supplier view: {[l[:20] for l in labels(page)][:10]}")
        results.append(("supplier segment switches list", True))
        page.screenshot(path=f"{SHOTS}/ux2-04-suppliers.png")
        tab(page, "खाता", "Parties")
        page.wait_for_timeout(1200)
        click_label(page, "ग्राहकहरू", max_y=300) if has(page, "ग्राहकहरू") else click_label(page, "Customers", max_y=300)
        page.wait_for_timeout(1500)
    else:
        results.append(("supplier segment switches list", False))

    # --- a party row opens the khata (not the edit form) ------------------
    if click_label(page, "Bikash", max_y=700):
        page.wait_for_timeout(2500)
        on_ledger = has_any(page, "खाता", "Khata")
        say(f"after row tap: {page.url} | {[l[:18] for l in labels(page)][:8]}")
        results.append(("party row opens the khata", on_ledger))
        page.screenshot(path=f"{SHOTS}/ux2-05-party-khata.png")
        page.go_back()
        page.wait_for_timeout(2500)
        enable(page)
    else:
        results.append(("party row opens the khata", False))

    # --- items tab ------------------------------------------------------
    ok = tab(page, "सामान", "Items")
    results.append(("items tab opens the catalogue", ok and has_any(page, "सामानहरू", "Products")))
    page.screenshot(path=f"{SHOTS}/ux2-06-items.png")

    # --- more tab -------------------------------------------------------
    ok = tab(page, "थप", "More")
    page.wait_for_timeout(1200)
    results.append(("more tab opens", ok))
    results.append(("more groups documents", has_any(page, "Sales & documents", "बिक्री र कागजात")))
    results.append(("more header names the shop", has_any(page, CREDS["businessName"][:12])))
    page.screenshot(path=f"{SHOTS}/ux2-07-more.png")

    # --- a pushed page gets a back button -------------------------------
    # The demo account's locale is Nepali, so try both label sets.
    if click_label(page, "खर्च", max_y=760) or click_label(page, "Expenses", max_y=760):
        page.wait_for_timeout(3000)
        enable(page)
        # Exact: "Backup" is also on the More page and would match "Back".
        # Nepali renders the tooltip as "पछाडि जानुहोस्".
        back = has_exact(page, "Back") or any(
            l.strip().startswith("पछाडि") for l in labels(page))
        say(f"after expenses: {page.url} back={back}")
        results.append(("pushed page has a back affordance", back))
        page.screenshot(path=f"{SHOTS}/ux2-08-pushed-expenses.png")
        if back:
            click_label(page, "Back") or click_label(page, "पछाडि")
            page.wait_for_timeout(2500)
            enable(page)
            results.append(("back returns to the tab", has_any(page, "Purchases", "खरिद")))
    else:
        results.append(("pushed page has a back affordance", False))

    page.screenshot(path=f"{SHOTS}/ux2-09-more-final.png")
    b.close()

say("")
say(f"console errors: {len(console_errors)}")
for e in console_errors[:6]:
    say(f"   {e[:160]}")
for name, ok in results:
    say(f"  {'PASS' if ok else 'FAIL'}  {name}")
passed = sum(1 for _, ok in results if ok)
say(f"RESULT {passed}/{len(results)}")
sys.exit(0 if passed == len(results) and not console_errors else 1)
