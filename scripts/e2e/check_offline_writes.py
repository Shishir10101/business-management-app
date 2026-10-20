"""Browser check for offline writes: sign in, create a customer online, then
create one while the browser is offline and look for the queued-save message.

Flutter renders into a shadow DOM, so this enables the semantics tree and
clicks real bounding boxes instead of guessing coordinates.
"""
import os
import sys
import time

from playwright.sync_api import sync_playwright

URL = "http://127.0.0.1:8080/"
SHOTS = "E:/business-management-app/docs/screenshots"
os.makedirs(SHOTS, exist_ok=True)

EMAIL = "admin@khata.local"
PASSWORD = "Admin@12345"

# Unique per run, so "the customer is in the list" cannot pass on an older row.
RUN = time.strftime("%H%M%S")
ONLINE_NAME = f"Online {RUN}"
OFFLINE_NAME = f"Offline {RUN}"

errors = []


def say(msg):
    print(msg, flush=True)


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


def enable_semantics(page):
    try:
        page.evaluate(
            "() => { const p = document.querySelector('flt-semantics-placeholder');"
            " if (p) p.click(); }"
        )
        page.wait_for_timeout(1500)
    except Exception as e:  # noqa: BLE001
        say(f"semantics enable failed: {e}")


def nodes(page):
    return page.evaluate(SEMANTICS_JS)


def labels(page):
    return [n["label"] for n in nodes(page) if n["label"]]


def buttons(page):
    return [n for n in nodes(page) if n["role"] == "button"]


def wait_for_text(page, needle, timeout_ms=12000):
    waited = 0
    while waited < timeout_ms:
        for text in labels(page):
            if needle.lower() in text.lower():
                return text
        page.wait_for_timeout(500)
        waited += 500
    return None


def click_button(page, wanted):
    """Exact label first, then a label that starts with it, then the widest."""
    btns = buttons(page)
    want = wanted.strip().lower()
    target = next((n for n in btns if n["label"].strip().lower() == want), None)
    if target is None:
        target = next(
            (n for n in btns if n["label"].strip().lower().startswith(want)), None
        )
    if target is None:
        say(f"  no exact '{wanted}' button; available: "
            f"{[b['label'][:26] for b in btns[:8]]}")
        return None
    page.mouse.click(target["cx"], target["cy"])
    return target["label"]


def inputs(page):
    """Real text fields only.

    `hasInput` is true for any wrapper that *contains* an input, including the
    full-page node — clicking that centre lands on whatever widget happens to
    be in the middle of the screen. A real field is one field tall.
    """
    return [
        n
        for n in nodes(page)
        if n["hasInput"] and 28 <= n["h"] <= 80 and n["w"] >= 100
    ]


def fill_field(page, text, index=0):
    fields = sorted(inputs(page), key=lambda n: n["cy"])
    if index >= len(fields):
        say(f"  only {len(fields)} field(s) on screen")
        return False
    target = fields[index]
    page.mouse.click(target["cx"], target["cy"])
    page.wait_for_timeout(400)
    page.keyboard.type(text, delay=20)
    return True


def open_page(page, hash_path, settle_ms=5000):
    page.goto(URL + hash_path, wait_until="load")
    page.wait_for_timeout(settle_ms)
    enable_semantics(page)
    return page.url


def scroll_down(page, pixels=900):
    """The forms are taller than the viewport; a click on a rect below the fold
    silently misses, so scroll first and re-read the semantics tree."""
    page.mouse.move(210, 500)
    page.mouse.wheel(0, pixels)
    page.wait_for_timeout(800)


def click_button_in_view(page, wanted):
    btns = [n for n in buttons(page) if 0 < n["cy"] < 860]
    want = wanted.strip().lower()
    target = next((n for n in btns if n["label"].strip().lower() == want), None)
    if target is None:
        say(f"  no '{wanted}' button in view; have "
            f"{[b['label'][:24] for b in btns[:8]]}")
        return None
    page.mouse.click(target["cx"], target["cy"])
    return target["label"]


with sync_playwright() as p:
    browser = p.chromium.launch(channel="chrome", headless=True)
    context = browser.new_context(viewport={"width": 420, "height": 880})
    page = context.new_page()
    page.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)
    page.on("pageerror", lambda e: errors.append(str(e)))
    posts = []
    page.on(
        "request",
        lambda r: posts.append(f"REQ {r.method} {r.url}")
        if r.method != "GET"
        else None,
    )
    page.on(
        "requestfailed",
        lambda r: posts.append(f"FAILED {r.method} {r.url} {r.failure}"),
    )

    page.goto(URL, wait_until="load", timeout=90000)
    page.wait_for_selector("flt-glass-pane", state="attached", timeout=90000)
    page.wait_for_timeout(8000)
    enable_semantics(page)
    say(f"loaded {page.url}")
    say(f"buttons: {[b['label'][:30] for b in buttons(page)][:10]}")

    if not fill_field(page, EMAIL, 0):
        say("FAIL: no email field")
        sys.exit(2)
    if not fill_field(page, PASSWORD, 1):
        say("FAIL: no password field")
        sys.exit(2)
    say(f"clicked sign-in: {click_button(page, 'sign in')}")

    for _ in range(30):
        page.wait_for_timeout(500)
        if "/login" not in page.url and "/register" not in page.url:
            break
    say(f"after sign-in: {page.url}")
    page.screenshot(path=f"{SHOTS}/offline-writes-01-dashboard.png")

    # --- online create -------------------------------------------------
    say(f"form url: {open_page(page, '#/customers/new')}")
    say(f"buttons: {[b['label'][:30] for b in buttons(page)][:10]}")
    say(f"fields: {len(inputs(page))}")
    if not fill_field(page, ONLINE_NAME, 0):
        say("FAIL: no name field on the customer form")
        sys.exit(2)
    scroll_down(page)
    say(f"clicked save: {click_button_in_view(page, 'create')}")
    page.wait_for_timeout(5000)
    online_note = wait_for_text(page, "created", 6000) or wait_for_text(page, "saved", 3000)
    say(f"online snackbar: {online_note!r}")
    page.screenshot(path=f"{SHOTS}/offline-writes-02-online-save.png")

    # The list is the real proof that the save reached the server.
    say(f"list url: {open_page(page, '#/customers')}")
    online_in_list = wait_for_text(page, ONLINE_NAME, 8000)
    say(f"online list contains the new customer: {online_in_list!r}")

    # --- offline create ------------------------------------------------
    context.set_offline(True)
    page.wait_for_timeout(2000)
    say(f"offline form url: {open_page(page, '#/customers/new', 6000)}")
    if not fill_field(page, OFFLINE_NAME, 0):
        say("FAIL: no name field while offline")
        sys.exit(2)
    scroll_down(page)
    say(f"clicked save (offline): {click_button_in_view(page, 'create')}")
    for i in range(25):
        page.wait_for_timeout(1000)
        every = [l for l in labels(page) if len(l) < 120]
        say(f"  t+{i + 1}s url={page.url}")
        if i in (1, 3, 6):
            say(f"    all labels: {[l[:90] for l in labels(page)][:16]}")
            page.screenshot(path=f"{SHOTS}/offline-writes-04-t{i + 1}.png")
        if "saved offline" in " ".join(labels(page)).lower():
            break
        if "/customers" in page.url and "new" not in page.url:
            break
    say(f"network: {posts}")
    queued_note = wait_for_text(page, "saved offline", 3000)
    say(f"offline snackbar: {queued_note!r}")
    say(f"offline url after save: {page.url}")
    page.screenshot(path=f"{SHOTS}/offline-writes-03-queued.png")

    banner = wait_for_text(page, "changes will sync", 3000)
    say(f"banner: {banner!r}")

    # --- back online: the queued write must reach the server -------------
    context.set_offline(False)
    page.wait_for_timeout(2000)
    say(f"sync url: {open_page(page, '#/sync', 6000)}")
    say(f"sync buttons: {[b['label'][:26] for b in buttons(page)][:8]}")
    say(f"clicked sync: {click_button(page, 'sync now')}")
    page.wait_for_timeout(9000)
    say(f"sync page labels: {[l[:40] for l in labels(page) if len(l) < 60][:10]}")
    page.screenshot(path=f"{SHOTS}/offline-writes-05-synced.png")

    say(f"list after sync: {open_page(page, '#/customers', 6000)}")
    synced = wait_for_text(page, OFFLINE_NAME, 8000)
    say(f"queued customer reached the server: {synced!r}")

    browser.close()

say(f"console errors: {len(errors)}")
for e in errors[:8]:
    say(f"  ERR: {e[:180]}")

ok_online = bool(online_in_list)
left_form = "/customers" in page.url and "/new" not in page.url
ok_offline = left_form or "offline" in (queued_note or "").lower()
ok_synced = bool(synced)
say(f"RESULT online_save={ok_online} offline_queue={ok_offline} synced={ok_synced} "
    f"(left_form={left_form}, snackbar={bool(queued_note)})")
sys.exit(0 if (ok_online and ok_offline and ok_synced) else 1)
