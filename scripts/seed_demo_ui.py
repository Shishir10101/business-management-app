#!/usr/bin/env python
"""Seed the demo Khata API (port 5000) with a business, products, parties and a sale."""
import json
import urllib.request

BASE = "http://127.0.0.1:5000/api"
TOKEN = None


def call(method, path, body=None):
    req = urllib.request.Request(BASE + path, method=method)
    req.add_header("Content-Type", "application/json")
    if TOKEN:
        req.add_header("Authorization", "Bearer " + TOKEN)
    data = json.dumps(body).encode() if body is not None else None
    try:
        with urllib.request.urlopen(req, data, timeout=30) as r:
            raw = r.read().decode()
            return r.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]


# login
st, res = call("POST", "/auth/login", {"email": "demo@khata.app", "password": "Demo@12345"})
print("login", st)
if st != 200:
    raise SystemExit("login failed: %s" % res)
TOKEN = res["accessToken"]

st, biz = call("POST", "/businesses", {
    "name": "Himalayan General Store",
    "type": "Retail",
    "address": "Chabahil, Kathmandu",
    "phone": "9801234567",
    "email": "store@khata.app",
    "panNumber": "301234567",
    "currency": "NPR",
})
print("business", st, (biz or {}).get("id") if isinstance(biz, dict) else biz)

st, me = call("GET", "/auth/me")
print("me", st, json.dumps(me)[:200] if st == 200 else me)

# re-login so the token carries the new business id
st, res = call("POST", "/auth/login", {"email": "demo@khata.app", "password": "Demo@12345"})
TOKEN = res["accessToken"]
print("relogin", st)

cats = {}
for name in ("Groceries", "Beverages", "Stationery"):
    st, c = call("POST", "/categories", {"name": name})
    print("category", name, st)
    if st in (200, 201) and isinstance(c, dict):
        cats[name] = c.get("id")

st, units = call("GET", "/units")
print("units", st, json.dumps(units)[:200])

unit_id = None
if isinstance(units, list) and units:
    unit_id = units[0].get("id")

products = [
    ("Basmati Rice 5kg", "Groceries", 125000, 105000, 13, 40, 10),
    ("Sunflower Oil 2L", "Groceries", 48000, 41000, 13, 25, 8),
    ("Wai Wai Noodles", "Groceries", 2500, 1800, 13, 200, 50),
    ("Coca-Cola 1.5L", "Beverages", 12000, 9500, 13, 60, 15),
    ("Himalayan Water 1L", "Beverages", 3000, 2000, 13, 120, 30),
    ("A4 Notebook 200pg", "Stationery", 15000, 11000, 13, 18, 6),
]
pid_by_name = {}
for name, cat, price, cost, tax, open_qty, minq in products:
    st, p = call("POST", "/products", {
        "name": name,
        "sku": name.split()[0][:4].upper() + "-" + str(abs(hash(name)) % 1000),
        "categoryId": cats.get(cat),
        "unitId": unit_id,
        "salePrice": price,
        "costPrice": cost,
        "taxRateBps": tax * 100,
        "minQuantity": minq,
        "openingQuantity": open_qty,
        "openingCostPrice": cost,
    })
    print("product", name, st, (p or {}).get("id") if isinstance(p, dict) else str(p)[:120])
    if st in (200, 201) and isinstance(p, dict):
        pid_by_name[name] = p.get("id")

cust = None
for n, ph in (("Ram Bahadur Shrestha", "9841001122"), ("Sita Kumari Thapa", "9851002233"),
              ("Bikash Traders", "9801223344")):
    st, c = call("POST", "/customers", {"name": n, "phone": ph, "type": "Customer"})
    print("customer", n, st, (c or {}).get("id") if isinstance(c, dict) else str(c)[:120])
    if cust is None:
        cust = c

sup = None
for n, ph in (("Kathmandu Wholesale Suppliers", "9812345566"),
              ("Everest Distributors", "9845677889")):
    st, s = call("POST", "/suppliers", {"name": n, "phone": ph, "type": "Supplier"})
    print("supplier", n, st, (s or {}).get("id") if isinstance(s, dict) else str(s)[:120])
    if sup is None:
        sup = s

if cust and pid_by_name:
    items = []
    for pname in ("Basmati Rice 5kg", "Wai Wai Noodles", "Himalayan Water 1L"):
        if pname in pid_by_name:
            items.append({"productId": pid_by_name[pname], "quantity": 2})
    st, sale = call("POST", "/sales", {
        "customerId": cust["id"],
        "saleType": "Credit",
        "saleDate": "2026-10-14T10:30:00",
        "items": items,
        "discountAmount": 0,
    })
    print("sale", st, json.dumps(sale)[:300] if isinstance(sale, dict) else str(sale)[:200])

    st, sale2 = call("POST", "/sales", {
        "customerId": cust["id"],
        "saleType": "Cash",
        "saleDate": "2026-10-15T11:00:00",
        "items": [{"productId": pid_by_name["Coca-Cola 1.5L"], "quantity": 6}],
        "discountAmount": 0,
    })
    print("sale2", st, json.dumps(sale2)[:200] if isinstance(sale2, dict) else str(sale2)[:200])

for path in ("/products", "/customers", "/suppliers", "/sales", "/reports/dashboard"):
    st, res = call("GET", path)
    n = len(res) if isinstance(res, list) else ("ok" if st == 200 else res)
    print("VERIFY", path, st, n if isinstance(n, int) else str(n)[:150])
