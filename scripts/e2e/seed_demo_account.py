"""Seed a demo account through the public API, then hand it to the browser run.

No credential is written into a shell command: the password is generated here,
used here, and only persisted to a temp file that the browser script reads.

Run: python scripts/e2e/seed_demo_account.py
"""

from __future__ import annotations

import json
import os
import secrets
import sys
import time
import urllib.error
import urllib.request

API = os.environ.get("KHATA_API", "http://127.0.0.1:5182/api")
OUT = os.path.join(os.path.dirname(__file__), "demo_account.json")


def call(method: str, path: str, body=None, token: str | None = None):
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(f"{API}{path}", data=data, method=method)
    request.add_header("Content-Type", "application/json")
    if token:
        request.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read().decode()
            return response.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as error:
        raw = error.read().decode()
        return error.code, raw


def wait_for_api(attempts: int = 40) -> None:
    for _ in range(attempts):
        try:
            with urllib.request.urlopen(f"{API}/products", timeout=3) as response:
                if response.status == 401:
                    return
        except urllib.error.HTTPError as error:
            if error.code == 401:
                return
        except Exception:
            pass
        time.sleep(2)
    sys.exit("API did not come up")


def main() -> None:
    wait_for_api()

    stamp = secrets.token_hex(4)
    email = f"shop{stamp}@khata.local"
    # Identity's policy wants upper, lower, digit and a symbol — guarantee them.
    password = "Shp9-" + secrets.token_urlsafe(9)
    full_name = "Sita Sharma"

    status, body = call("POST", "/auth/register", {
        "fullName": full_name,
        "email": email,
        "password": password,
        "confirmPassword": password,
        "phoneNumber": "9841234567",
    })
    if status not in (200, 201):
        sys.exit(f"register failed {status}: {body}")

    # Register does not hand back a token; sign in to get one.
    status, auth = call("POST", "/auth/login", {"email": email, "password": password})
    if status != 200:
        sys.exit(f"login failed {status}: {auth}")
    token = auth["accessToken"]

    status, business = call("POST", "/businesses", {
        "name": f"Himal Kirana {stamp}",
        "currency": "NPR",
        "addressLine": "Lakeside Road",
        "city": "Pokhara",
        "district": "Kaski",
    }, token)
    if status not in (200, 201):
        sys.exit(f"business failed {status}: {business}")

    business_id = business["id"]
    status, auth = call("POST", f"/businesses/{business_id}/switch", {}, token)
    if status != 200:
        sys.exit(f"switch failed {status}: {auth}")
    token = auth["accessToken"]

    products = """name,sku,category,unit,costPrice,sellingPrice,taxRate,openingQuantity,minQuantity
Basmati Rice 5kg,RICE-5,Grains,kg,850.00,950.00,13,40,10
Sunflower Oil 1L,OIL-1,Cooking Oil,L,220.50,255.00,13,24,6
Wai Wai Noodles,WAI-1,Snacks,pc,18,25,13,120,24
Mustang Coffee 100g,COF-1,Beverages,pc,240,310,13,18,6
Sugar 1kg,SUG-1,Grains,kg,95,110,13,60,15
Tata Tea 250g,TEA-1,Beverages,pc,180,225,13,30,8
Detergent 1kg,DET-1,Household,pc,150,195,13,22,5
Biscuit Pack,BIS-1,Snacks,pc,35,50,13,80,20
"""
    status, result = call("POST", "/import/products", {"csv": products}, token)
    if status != 200:
        sys.exit(f"product import failed {status}: {result}")

    customers = """name,phone,openingBalance,city,district
Ram Bahadur Thapa,9841000001,1500.00,Pokhara,Kaski
Gita Gurung,9841000002,0,Pokhara,Kaski
Bikash Shrestha,9841000003,3200.50,Lekhnath,Kaski
Sita Magar,9841000004,0,Butwal,Rupandehi
Hari Prasad,9841000005,750.00,Biratnagar,Morang
"""
    status, result_c = call("POST", "/import/customers", {"csv": customers}, token)
    if status != 200:
        sys.exit(f"customer import failed {status}: {result_c}")

    # One credit sale so the dashboard and the khata have something to show.
    status, product_page = call("GET", "/products?pageSize=10", None, token)
    first = product_page["data"][0]
    status, customers_page = call("GET", "/customers?pageSize=10", None, token)
    first_customer = customers_page["data"][0]

    sale = {
        "customerId": first_customer["id"],
        "saleType": "Credit",
        "saleDate": time.strftime("%Y-%m-%d"),
        "discountAmount": 0,
        "paidAmount": 0,
        "notes": "Seeded by the browser run",
        "items": [
            {
                "productId": first["id"],
                "quantity": 2,
                "unitPrice": first["sellingPrice"],
                "discountAmount": 0,
                "taxRateBps": 0,
            }
        ],
    }
    status, sale_body = call("POST", "/sales", sale, token)
    sale_ok = status in (200, 201)

    payload = {
        "email": email,
        "password": password,
        "fullName": full_name,
        "businessId": business_id,
        "businessName": business["name"],
        "products": result["created"],
        "customers": result_c["created"],
        "saleCreated": sale_ok,
        "saleError": None if sale_ok else f"{status}: {sale_body}",
    }
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)

    print(json.dumps({k: v for k, v in payload.items() if k != "password"}, indent=2))


if __name__ == "__main__":
    main()
