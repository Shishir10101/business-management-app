#!/usr/bin/env python3
"""Phase 10 live E2E: notifications, reminders, backup/restore against the demo API."""
import json
import urllib.request
import urllib.error
import uuid
import datetime

BASE = "http://localhost:5182"
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

PASS, FAIL = [], []


def parse_local(value):
    """The API answers with Nepal-local (UTC+05:45) naive timestamps by design;
    an explicit offset is honoured as-is so both forms compare correctly."""
    dt = datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=datetime.timezone(datetime.timedelta(minutes=5 * 60 + 45)))
    return dt


def now_local():
    return datetime.datetime.now(datetime.timezone.utc)



def call(method, path, token=None, body=None, raw=False):
    url = BASE + path
    data = None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    if body is not None:
        data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with opener.open(req, timeout=30) as resp:
            payload = resp.read()
            if raw:
                return resp.status, payload, dict(resp.headers)
            return resp.status, (json.loads(payload) if payload else None), dict(resp.headers)
    except urllib.error.HTTPError as e:
        payload = e.read()
        if raw:
            return e.code, payload, dict(e.headers)
        try:
            return e.code, json.loads(payload) if payload else None, dict(e.headers)
        except Exception:
            return e.code, payload.decode(errors="replace"), dict(e.headers)


def check(label, cond, detail=""):
    (PASS if cond else FAIL).append(label)
    print(("  PASS  " if cond else "  FAIL  ") + label + (f"  [{detail}]" if detail and not cond else ""))


def owner_client():
    email = f"p10-{uuid.uuid4().hex[:12]}@example.com"
    st, _, _ = call("POST", "/api/auth/register", body={
        "fullName": "Phase Ten", "email": email, "password": "Passw0rd123",
        "phoneNumber": None})
    assert st in (200, 201), st
    st, auth, _ = call("POST", "/api/auth/login", body={"email": email, "password": "Passw0rd123"})
    assert st == 200, (st, auth)
    token = auth["accessToken"]
    st, biz, _ = call("POST", "/api/businesses", token=token, body={
        "name": "P10 Shop " + uuid.uuid4().hex[:6], "currency": "NPR"})
    assert st in (200, 201), (st, biz)
    st, auth2, _ = call("POST", f"/api/businesses/{biz['id']}/switch", token=token, body={})
    assert st == 200, (st, auth2)
    return auth2["accessToken"]


print("\n=== 1. Notification feed starts empty ===")
t = owner_client()
st, feed, _ = call("GET", "/api/notifications", token=t)
check("feed empty", st == 200 and feed["data"] == [], f"{st} {feed}")
st, unread, _ = call("GET", "/api/notifications/unread-count", token=t)
check("unread 0", st == 200 and unread["count"] == 0, f"{st} {unread}")

print("\n=== 2. Device registration (idempotent per token) ===")
tok = "tok-" + uuid.uuid4().hex
st, d1, _ = call("POST", "/api/notifications/devices", token=t,
                 body={"token": tok, "platform": "Android"})
check("register 201", st == 201, f"{st} {d1}")
st, d2, _ = call("POST", "/api/notifications/devices", token=t,
                 body={"token": tok, "platform": "Ios"})
check("re-register same id (refresh)", st == 201 and d2["id"] == d1["id"], f"{st} {d1} {d2}")
check("platform refreshed", d2["platform"] == "Ios", d2)
st, devices, _ = call("GET", "/api/notifications/devices", token=t)
check("exactly one device row", st == 200 and len(devices) == 1, f"{st} {devices}")
st, _, _ = call("POST", "/api/notifications/devices", token=t, body={"token": "", "platform": "Android"})
check("empty token 400", st == 400, st)
st, _, _ = call("DELETE", f"/api/notifications/devices?token={tok}", token=t)
check("unregister 204", st == 204, st)
st, devices, _ = call("GET", "/api/notifications/devices", token=t)
check("device list empty after unregister", devices == [], devices)

print("\n=== 3. Settings default + update ===")
st, s, _ = call("GET", "/api/notifications/settings", token=t)
check("all enabled by default", st == 200 and s == {
    "pushEnabled": True, "reminderEnabled": True, "lowStockEnabled": True,
    "paymentDueEnabled": True, "backupEnabled": True, "systemEnabled": True}, f"{st} {s}")
st, s2, _ = call("PUT", "/api/notifications/settings", token=t, body={
    "pushEnabled": True, "reminderEnabled": False, "lowStockEnabled": False,
    "paymentDueEnabled": True, "backupEnabled": False, "systemEnabled": True})
check("update persisted", st == 200 and s2["reminderEnabled"] is False
      and s2["lowStockEnabled"] is False and s2["backupEnabled"] is False, f"{st} {s2}")
st, s3, _ = call("GET", "/api/notifications/settings", token=t)
check("re-read matches", s3 == s2, s3)

print("\n=== 4. Reminders: create, list, engine ===")
future = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=1)).isoformat()
st, r_future, _ = call("POST", "/api/reminders", token=t, body={
    "title": "Future task", "notes": None, "dueAt": future, "repeat": "None"})
check("create 201 pending", st == 201 and r_future["status"] == "Pending", f"{st} {r_future}")
st, _, _ = call("POST", "/api/reminders", token=t, body={"title": "", "dueAt": future, "repeat": "None"})
check("empty title 400", st == 400, st)
st, fired, _ = call("POST", "/api/reminders/process-due", token=t, body={})
check("future reminder not fired", st == 200 and fired["fired"] == 0, f"{st} {fired}")

overdue = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(minutes=10)).isoformat()
st, r_old, _ = call("POST", "/api/reminders", token=t, body={
    "title": "Overdue bill", "notes": "Call Ram", "dueAt": overdue, "repeat": "None"})
check("overdue created", st == 201, f"{st} {r_old}")
st, fired, _ = call("POST", "/api/reminders/process-due", token=t, body={})
check("one reminder fired", st == 200 and fired["fired"] == 1, f"{st} {fired}")
st, fired2, _ = call("POST", "/api/reminders/process-due", token=t, body={})
check("not re-fired (idempotent)", fired2["fired"] == 0, fired2)
st, pending, _ = call("GET", "/api/reminders?status=Pending", token=t)
check("one-shot completed", len(pending["data"]) == 1 and pending["data"][0]["id"] == r_future["id"], pending)
st, done, _ = call("GET", "/api/reminders?status=Done", token=t)
check("done row is the overdue one", len(done["data"]) == 1 and done["data"][0]["id"] == r_old["id"], done)
check("completedAt set", done["data"][0]["completedAt"] is not None, done)

st, nf, _ = call("GET", "/api/notifications", token=t)
check("notification written for reminder", len(nf["data"]) == 1
      and nf["data"][0]["title"] == "Overdue bill"
      and nf["data"][0]["category"] == "Reminder"
      and nf["data"][0]["referenceId"] == r_old["id"], nf)
st, unread, _ = call("GET", "/api/notifications/unread-count", token=t)
check("unread 1", unread["count"] == 1, unread)

print("\n=== 5. Recurring reminder reschedules to the future ===")
old_weekly = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=21)).isoformat()
st, r_weekly, _ = call("POST", "/api/reminders", token=t, body={
    "title": "Weekly report", "dueAt": old_weekly, "repeat": "Weekly"})
check("weekly created", st == 201, f"{st} {r_weekly}")
st, fired, _ = call("POST", "/api/reminders/process-due", token=t, body={})
check("weekly fired once", fired["fired"] == 1, fired)
st, rw, _ = call("GET", f"/api/reminders/{r_weekly['id']}", token=t)
next_due = parse_local(rw["dueAt"])
check("still pending", rw["status"] == "Pending", rw)
check("advanced to the future", next_due > now_local(), rw["dueAt"])

print("\n=== 6. Notification read state ===")
# Two reminders have fired by now, each raising a notification. Read the
# overdue one and assert the count drops by exactly one.
st, feed, _ = call("GET", "/api/notifications", token=t)
check("two notifications present", len(feed["data"]) == 2, feed)
overdue_note = next(n for n in feed["data"] if n["title"] == "Overdue bill")
st, _, _ = call("POST", f"/api/notifications/{overdue_note['id']}/read", token=t)
check("mark read", st == 200, st)
st, unread, _ = call("GET", "/api/notifications/unread-count", token=t)
check("unread 1 after reading one of two", unread["count"] == 1, unread)
st, unread_only, _ = call("GET", "/api/notifications?unreadOnly=true", token=t)
check("unreadOnly hides the read one",
      len(unread_only["data"]) == 1 and unread_only["data"][0]["title"] == "Weekly report",
      unread_only)
st, _, _ = call("POST", "/api/notifications/read-all", token=t)
check("read-all 200", st == 200, st)
st, unread, _ = call("GET", "/api/notifications/unread-count", token=t)
check("unread 0 after read-all", unread["count"] == 0, unread)

print("\n=== 7. Seed a dataset then export ===")
st, prod, _ = call("POST", "/api/products", token=t, body={
    "name": "E2E Widget", "costPrice": 3000, "sellingPrice": 5000,
    "taxRateBps": 0, "openingQuantity": 20})
check("product created", st in (200, 201), f"{st} {prod}")
st, cust, _ = call("POST", "/api/customers", token=t, body={"name": "E2E Customer"})
check("customer created", st in (200, 201), f"{st} {cust}")
st, sup, _ = call("POST", "/api/suppliers", token=t, body={"name": "E2E Supplier"})
check("supplier created", st in (200, 201), f"{st} {sup}")
st, sale, _ = call("POST", "/api/sales", token=t, body={
    "customerId": cust["id"], "saleType": "Credit",
    "items": [{"productId": prod["id"], "quantity": 1, "unitPrice": 5000}], "paidAmount": 0})
check("sale created", st in (200, 201), f"{st} {sale}")
st, pur, _ = call("POST", "/api/purchases", token=t, body={
    "supplierId": sup["id"], "purchaseType": "Credit",
    "items": [{"productId": prod["id"], "quantity": 2, "unitPrice": 3000}], "paidAmount": 0})
check("purchase created", st in (200, 201), f"{st} {pur}")
st, exp, _ = call("POST", "/api/expenses", token=t, body={"category": "Rent", "amount": 150000})
check("expense created", st in (200, 201), f"{st} {exp}")
st, inc, _ = call("POST", "/api/incomes", token=t, body={"source": "Consulting", "amount": 250000})
check("income created", st in (200, 201), f"{st} {inc}")

st, raw, hdrs = call("GET", "/api/backup/export", token=t, raw=True)
check("export 200", st == 200, st)
check("content-type json", hdrs.get("Content-Type", "").startswith("application/json"), hdrs.get("Content-Type"))
check("content-disposition filename", "khata-backup-" in hdrs.get("Content-Disposition", ""), hdrs.get("Content-Disposition"))
backup = json.loads(raw)
check("version 1", backup["version"] == 1, backup.get("version"))
check("product exported w/ stock", len(backup["products"]) == 1
      and backup["products"][0]["stockQuantity"] == 21.0, backup["products"])
check("5 seeded payment methods", len(backup["paymentMethods"]) == 5, len(backup["paymentMethods"]))
check("sale exported", len(backup["sales"]) == 1 and len(backup["sales"][0]["items"]) == 1, backup["sales"])
check("purchase exported", len(backup["purchases"]) == 1, len(backup["purchases"]))
check("expense+income exported", len(backup["expenses"]) == 1 and len(backup["incomes"]) == 1, "")

print("\n=== 8. Restore into a FRESH business ===")
t2 = owner_client()
st, res, _ = call("POST", "/api/backup/restore", token=t2, body=backup)
check("restore 200", st == 200, f"{st} {res}")
if st == 200:
    check("inserted product/customer/supplier", res["productsInserted"] == 1
          and res["customersInserted"] == 1 and res["suppliersInserted"] == 1, res)
    check("inserted sale/purchase/expense/income", res["salesInserted"] == 1
          and res["purchasesInserted"] == 1 and res["expensesInserted"] == 1
          and res["incomesInserted"] == 1, res)
    st, prods, _ = call("GET", "/api/products", token=t2)
    check("restored product readable", len(prods["data"]) == 1
          and prods["data"][0]["name"] == "E2E Widget"
          and prods["data"][0]["stockQuantity"] == 21.0, prods)
    st, sales2, _ = call("GET", "/api/sales", token=t2)
    check("restored sale readable w/ number", len(sales2["data"]) == 1
          and sales2["data"][0]["invoiceNumber"] == "INV-00001"
          and sales2["data"][0]["totalAmount"] == 5000, sales2)

print("\n=== 9. Restore twice = merge (skip, never overwrite) ===")
st, res2, _ = call("POST", "/api/backup/restore", token=t2, body=backup)
check("second restore 200", st == 200, f"{st} {res2}")
if st == 200:
    check("nothing re-inserted", res2["productsInserted"] == 0 and res2["salesInserted"] == 0, res2)
    check("all skipped", res2["productsSkipped"] == 1 and res2["salesSkipped"] == 1, res2)
st, prods2, _ = call("GET", "/api/products", token=t2)
check("still exactly one product", len(prods2["data"]) == 1, prods2)

print("\n=== 10. Local edit survives a re-restore ===")
st, _, _ = call("PUT", f"/api/products/{prods2['data'][0]['id']}", token=t2, body={
    "name": "Renamed Locally", "costPrice": 3000, "sellingPrice": 5000,
    "taxRateBps": 0, "isActive": True})
check("rename 200", st == 200, st)
st, _, _ = call("POST", "/api/backup/restore", token=t2, body=backup)
st, after, _ = call("GET", "/api/products", token=t2)
check("local edit not overwritten", after["data"][0]["name"] == "Renamed Locally", after)

print("\n=== 11. Newer backup version rejected ===")
future_backup = dict(backup)
future_backup["version"] = 99
st, body, _ = call("POST", "/api/backup/restore", token=t2, body=future_backup)
check("version 99 → 400", st == 400, f"{st} {body}")

print("\n=== 12. Isolation: other business untouched ===")
st, prodsA, _ = call("GET", "/api/products", token=t)
st, prodsB, _ = call("GET", "/api/products", token=t2)
check("source business unchanged", len(prodsA["data"]) == 1 and prodsA["data"][0]["name"] == "E2E Widget", prodsA)
check("target business keeps its own", len(prodsB["data"]) == 1, prodsB)

print(f"\n{'='*60}\nRESULT: {len(PASS)} passed, {len(FAIL)} failed")
if FAIL:
    print("FAILED:")
    for f in FAIL:
        print("  -", f)
