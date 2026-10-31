"""Create one of every entity the UI can navigate to, so detail/edit screens
have real ids to open.

Runs after scripts/e2e/seed_demo_account.py and writes ui_fixtures.json next to
this file.

    KHATA_API=http://127.0.0.1:5000/api python scripts/e2e/seed_ui_fixtures.py
"""

from __future__ import annotations

import json
import os
import pathlib
import sys
import urllib.error
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent
API = os.environ.get("KHATA_API", "http://127.0.0.1:5000/api")
account = json.loads((HERE / "demo_account.json").read_text(encoding="utf-8"))
OUT = HERE / "ui_fixtures.json"


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
        return error.code, error.read().decode()[:300]


def must(label, status, body):
    if not (200 <= status < 300):
        print(f"  FAIL {label}: {status} {body}")
        sys.exit(1)
    return body


def main() -> int:
    status, auth = call("POST", "/auth/login", {
        "email": account["email"], "password": account["password"]})
    token = must("login", status, auth)["accessToken"]

    status, products = call("GET", "/products?page=1&pageSize=5", token=token)
    product_id = must("products", status, products)["data"][0]["id"]

    status, customers = call("GET", "/customers?page=1&pageSize=5", token=token)
    customer_id = must("customers", status, customers)["data"][0]["id"]

    status, suppliers = call("GET", "/suppliers?page=1&pageSize=5", token=token)
    supplier_rows = must("suppliers", status, suppliers)["data"]
    if supplier_rows:
        supplier_id = supplier_rows[0]["id"]
    else:
        status, created = call("POST", "/suppliers", {
            "name": "UI Supplier", "phoneNumber": "9800000001"}, token)
        supplier_id = must("supplier create", status, created)["id"]

    fixtures = {
        "productId": product_id,
        "customerId": customer_id,
        "supplierId": supplier_id,
        "saleId": None,
        "purchaseId": None,
        "invoiceId": None,
        "quotationId": None,
        "expenseId": None,
        "incomeId": None,
        "reminderId": None,
    }

    status, sales = call("GET", "/sales?page=1&pageSize=5", token=token)
    rows = must("sales", status, sales)["data"]
    fixtures["saleId"] = rows[0]["id"] if rows else None

    status, body = call("POST", "/purchases", {
        "supplierId": supplier_id,
        "purchaseType": "Credit",
        "items": [{"productId": product_id, "quantity": 2, "unitPrice": 5000}],
        "paidAmount": 0,
        "notes": "UI fixture",
    }, token)
    fixtures["purchaseId"] = must("purchase", status, body)["id"]

    status, body = call("POST", "/invoices", {
        "customerId": customer_id,
        "items": [{"description": "Consulting", "quantity": 1, "unitPrice": 150000}],
        "notes": "UI fixture",
    }, token)
    fixtures["invoiceId"] = must("invoice", status, body)["id"]

    status, body = call("POST", "/quotations", {
        "customerId": customer_id,
        "items": [{"description": "Quote line", "quantity": 1, "unitPrice": 90000}],
        "notes": "UI fixture",
    }, token)
    fixtures["quotationId"] = must("quotation", status, body)["id"]

    status, body = call("POST", "/payments", {
        "partyType": "Customer",
        "partyId": customer_id,
        "amount": 2500,
        "methodCode": "cash",
        "notes": "UI fixture",
    }, token)
    must("payment", status, body)

    status, body = call("POST", "/expenses", {
        "category": "Rent", "amount": 120000, "description": "UI fixture"}, token)
    fixtures["expenseId"] = must("expense", status, body)["id"]

    status, body = call("POST", "/incomes", {
        "source": "Other", "amount": 50000, "description": "UI fixture"}, token)
    fixtures["incomeId"] = must("income", status, body)["id"]

    status, body = call("POST", "/reminders", {
        "title": "UI fixture reminder",
        "notes": "created by the audit",
        "dueAt": "2026-10-25T09:00:00Z",
        "repeat": "None",
        "relatedEntityType": None,
        "relatedEntityId": None,
    }, token)
    fixtures["reminderId"] = must("reminder", status, body)["id"]

    OUT.write_text(json.dumps(fixtures, indent=2), encoding="utf-8")
    print(json.dumps(fixtures, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
