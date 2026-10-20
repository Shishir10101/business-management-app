# API Design

> RESTful API specification for Nepal Digital Khata.
> Base URL: `https://api.khata.app` (production), `https://localhost:5001` (dev)

---

## 1. Conventions

### 1.1 Authentication

All endpoints (except `/api/auth/login`, `/api/auth/register`, `/api/auth/refresh`)
require:

```
Authorization: Bearer <access-token>
```

The JWT contains claims: `sub` (user id), `bid` (active business id),
`name`, `email`, `roles`, `perms`.

### 1.2 Content Type

```
Content-Type: application/json
Accept: application/json
```

### 1.3 Pagination

```
GET /api/sales?page=1&pageSize=20
```

Response:

```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 157,
    "totalPages": 8,
    "hasNext": true,
    "hasPrev": false
  }
}
```

### 1.4 Filtering, Sorting, Searching

| Param | Example | Description |
|-------|---------|-------------|
| `search` | `?search=rice` | Free-text search on relevant fields |
| `dateFrom` | `?dateFrom=2026-01-01` | Date range start |
| `dateTo` | `?dateTo=2026-01-31` | Date range end |
| `sortBy` | `?sortBy=date` | Sort field |
| `sortDir` | `?sortDir=desc` | `asc` or `desc` |
| `status` | `?status=paid` | Enum filter |
| `customerId` | `?customerId=5` | Foreign key filter |

### 1.5 Error Responses

All errors use RFC 7807 Problem Details:

```json
{
  "type": "https://api.khata.app/errors/validation",
  "title": "Validation failed",
  "status": 400,
  "detail": "One or more fields have validation errors.",
  "instance": "/api/sales",
  "errors": {
    "customerName": ["Customer name is required."],
    "items": ["At least one item is required."]
  },
  "traceId": "00-7f3a8b2c..."
}
```

### 1.6 HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success (GET, PUT, PATCH) |
| 201 | Created (POST) |
| 204 | No content (DELETE) |
| 400 | Bad request / validation error |
| 401 | Not authenticated |
| 403 | Not authorized (missing permission) |
| 404 | Not found |
| 409 | Conflict (duplicate, sync conflict) |
| 422 | Unprocessable entity (business rule violation) |
| 429 | Rate limited |
| 500 | Server error |

### 1.7 Money in Responses

All monetary values are sent as integers (paisa):

```json
{ "totalAmount": 123456 }   // = NPR 1,234.56
{ "paidAmount": 50000 }     // = NPR 500.00
```

### 1.8 Dates in Responses

All dates are ISO 8601 in Gregorian calendar (server-side):
the client converts to Bikram Sambat for display.

```json
{ "saleDate": "2026-10-08" }
{ "createdAt": "2026-10-08T15:24:01Z" }
```

---

## 2. Auth Endpoints

### POST /api/auth/register

```json
// Request
{
  "fullName": "Ram Sharma",
  "email": "ram@example.com",
  "password": "SecurePass123!",
  "phoneNumber": "+9779812345678",
  "locale": "ne"
}

// Response 201
{
  "userId": 1,
  "email": "ram@example.com",
  "fullName": "Ram Sharma",
  "accessToken": "eyJhbG...",
  "refreshToken": "dGhpc0lz...",
  "expiresIn": 3600
}
```

### POST /api/auth/login

```json
// Request
{
  "email": "ram@example.com",
  "password": "SecurePass123!"
}

// Response 200
{
  "userId": 1,
  "email": "ram@example.com",
  "fullName": "Ram Sharma",
  "accessToken": "eyJhbG...",
  "refreshToken": "dGhpc0lz...",
  "expiresIn": 3600,
  "businesses": [
    { "id": 1, "name": "Sharma Grocery", "role": "Owner" }
  ]
}
```

### POST /api/auth/refresh

```json
// Request
{ "refreshToken": "dGhpc0lz..." }

// Response 200
{
  "accessToken": "eyJhbG...",
  "refreshToken": "bmV3UmVm...",
  "expiresIn": 3600
}
```

### POST /api/auth/logout

Revokes the refresh token. Access token expires naturally.

### GET /api/auth/me

Returns current user profile + active business context.

### PUT /api/auth/profile

Update user profile (name, phone, locale, timezone, profile image).

### POST /api/auth/change-password

```json
{ "currentPassword": "...", "newPassword": "..." }
```

---

## 3. Business Endpoints

All endpoints below require `Authorization: Bearer <token>`.
Member/staff endpoints (marked `settings.manage`) require the caller's role in
their **active** business to be Owner or Admin; the service additionally verifies
membership and role inside the **target** business on every call. Non-members
receive `404` (business existence is not leaked cross-tenant).

### GET /api/businesses

List businesses the current user belongs to (with the caller's role in each).

### POST /api/businesses

```json
// Request (only "name" is required)
{
  "name": "Sharma Grocery Store",
  "type": "Retail",
  "panNumber": "123456789",
  "phoneNumber": "+9779812345678",
  "addressLine": "Chabahil, Kathmandu",
  "city": "Kathmandu",
  "district": "Kathmandu",
  "province": "Bagmati",
  "currency": "NPR"
}
```

Creates the business; the creator becomes its Owner and it becomes their active
business. Returns `201` with the business DTO (including `"role": "Owner"`).

### GET /api/businesses/{id}

### PUT /api/businesses/{id}

`settings.manage` permission. Owner/Admin only.

### DELETE /api/businesses/{id}

`settings.manage` permission. Soft-delete; **Owner only**. Users whose active
business was this one lose their selection.

### POST /api/businesses/{id}/switch

Sets the active business (drives the `bid` claim) and issues a **fresh token
pair** scoped to the selected business:

```json
// Response 200 (same shape as login)
{
  "userId": 1,
  "email": "owner@khata.local",
  "fullName": "Ram Sharma",
  "accessToken": "eyJhbG...",
  "refreshToken": "...",
  "expiresIn": 3600,
  "businesses": [ { "id": 2, "name": "Clothing Shop", "role": "Owner" } ]
}
```

The new access token carries the selected business's `bid` claim and the
permission codes of the caller's role **in that business**.

### GET /api/businesses/{id}/members

`settings.manage` permission. List staff members with email, name and role.

### POST /api/businesses/{id}/members

`settings.manage` permission. Invite a user (must already have an account)
with one of the system roles: Owner, Admin, Manager, Accountant, SalesStaff,
InventoryStaff, Viewer. Returns `409` if already a member, `404` if the email
has no account.

### PUT /api/businesses/{id}/members/{memberId}

`settings.manage` permission. Update member role. Returns `422` when demoting
the only Owner.

### DELETE /api/businesses/{id}/members/{memberId}

`settings.manage` permission. Remove a member. Returns `422` when removing the
only Owner.

### GET /api/businesses/{id}/bank-accounts

### POST /api/businesses/{id}/bank-accounts

### PUT /api/businesses/{id}/bank-accounts/{accountId}

### DELETE /api/businesses/{id}/bank-accounts/{accountId}

---

## 4. Product & Category Endpoints

Implemented in Phase 3. All endpoints are scoped to the caller's **active
business** (JWT `bid` claim): another business's products return `404`, never
`403` (existence is not leaked).

Naming deviations from the earlier sketch: the tax rate travels as
**`taxRateBps`** (basis points, `1300` = 13.00%) and stock fields are
**`openingQuantity`** / **`minQuantity`** (decimals, `3` = kg-friendly).
Prices stay integer paisa.

### GET /api/products

`products.view` permission.

```
?search=rice&categoryId=3&isActive=true&page=1&pageSize=20
```

Search matches name, SKU and barcode (case-insensitive). Returns a paged
result where each item carries its current stock flattened in:

```json
{
  "data": [
    {
      "id": 1,
      "name": "Basmati Rice 5kg",
      "categoryId": 3,
      "categoryName": "Grocery",
      "unitId": 1,
      "unitShortName": "pc",
      "sku": "RICE-5KG",
      "barcode": "1234567890123",
      "costPrice": 85000,
      "sellingPrice": 110000,
      "wholesalePrice": 95000,
      "taxRateBps": 0,
      "isActive": true,
      "stockQuantity": 50,
      "minQuantity": 10,
      "isLowStock": false,
      "createdAt": "2026-10-13T09:00:00Z",
      "updatedAt": "2026-10-13T09:00:00Z"
    }
  ],
  "pagination": { "page": 1, "pageSize": 20, "totalItems": 1, "totalPages": 1, "hasNext": false, "hasPrev": false }
}
```

### GET /api/products/{id}

`products.view`. Single product with stock (same shape as list items).

### POST /api/products

`products.create`. Creates the product **and its stock row** in one
transaction. `openingQuantity > 0` also records the first
`Opening` stock movement, so the movement ledger starts auditable.

```json
{
  "name": "Basmati Rice 5kg",
  "categoryId": 3,
  "unitId": 1,
  "sku": "RICE-5KG",
  "barcode": "1234567890123",
  "description": "Premium aged basmati",
  "costPrice": 85000,
  "sellingPrice": 110000,
  "wholesalePrice": 95000,
  "taxRateBps": 1300,
  "isActive": true,
  "openingQuantity": 50,
  "minQuantity": 10
}
```

`409` when SKU or barcode is already used by another product of this business.
`404` when categoryId/unitId is unknown.

### PUT /api/products/{id}

`products.edit`. Full update. **Stock quantity is deliberately not editable
here** — quantities change only through `POST /api/inventory/{productId}/adjust`,
which appends a movement. Updates `minQuantity` only.

### DELETE /api/products/{id}

`products.edit`. Soft delete. Stock movements survive (the ledger is
immutable); the product disappears from the catalog and inventory lists.

### GET /api/categories

`products.view`. All categories with `productCount`.

```json
[{ "id": 1, "name": "General", "description": null, "parentId": null, "parentName": null, "isActive": true, "productCount": 12 }]
```

### POST /api/categories

`products.create`. Body: `{ name, description?, parentId? }`.

### PUT /api/categories/{id}

`products.edit`. Body: `{ name, description?, parentId?, isActive }`.

### DELETE /api/categories/{id}

`products.edit`. Soft delete. Products in the category keep working
(`categoryId` cleared). `422 category_has_children` while active
sub-categories exist.

### GET /api/units

`products.view`. All units of measure.

```json
[{ "id": 1, "name": "Piece", "shortName": "pc", "isActive": true, "productCount": 20 }]
```

A new business is seeded with Piece, Kilogram, Gram, Litre, Box, Dozen
plus a "General" category — the catalog is usable immediately.

### POST /api/units

`products.create`. Body: `{ name, shortName }`. `409` when the name already
exists (names are unique per business, case-insensitive).

### PUT /api/units/{id}

`products.edit`. Body: `{ name, shortName, isActive }`.

### DELETE /api/units/{id}

`products.edit`. Soft delete; products keep working without a unit.

---

## 5. Inventory Endpoints

Implemented in Phase 3. Every adjustment is an append-only
`stock_movement` row plus a cached `stock.quantity` update in the **same
transaction**. The movement ledger can never be edited or deleted — the
DbContext rejects `Modified`/`Deleted` states for immutable entities.

### GET /api/inventory

`inventory.view`. Stock list (products + current quantity, same shape as
`GET /api/products`).

```
?search=rice&lowStockOnly=true&sortBy=quantity&page=1&pageSize=20
```

`sortBy`: `name` (default) or `quantity` (ascending — most urgent first).

### GET /api/inventory/low-stock

`inventory.view`. Products at or below their minimum
(`quantity <= minQuantity && minQuantity > 0`; a minimum of 0 means
"no alert threshold").

### POST /api/inventory/{productId}/adjust

`inventory.adjust`. Signed adjustment: positive = stock in, negative = out.
Zero is rejected (`400`), and stock may not go negative (`422`).

```json
{
  "quantity": -18,
  "notes": "Sold at counter"
}
```

Response:

```json
{
  "productId": 5,
  "productName": "Basmati Rice 5kg",
  "quantity": 32,
  "minQuantity": 10,
  "movement": {
    "id": 91,
    "productId": 5,
    "productName": "Basmati Rice 5kg",
    "movementType": "AdjustmentOut",
    "quantity": -18,
    "balanceAfter": 32,
    "referenceType": "adjustment",
    "referenceId": null,
    "notes": "Sold at counter",
    "movementDate": "2026-10-13",
    "createdAt": "2026-10-13T11:30:00Z"
  }
}
```

`movementType` is a string enum: `Opening`, `Purchase`, `Sale`, `ReturnIn`,
`ReturnOut`, `AdjustmentIn`, `AdjustmentOut`. (Purchase/Sale/Return movements
are written by later phases — Phase 5 onward.)

### GET /api/inventory/{productId}/movements

`inventory.view`. Append-only movement history for one product, newest
first (`movementDate` desc, then `id` desc). Paged, same envelope as other
list endpoints. `404` when the product does not exist in this business.

---

## 6. Customer Endpoints

Implemented in Phase 4. Every endpoint requires an authenticated user with an
active business (JWT `bid` claim); queries are scoped to that business by the
tenant filter, so another business's customer returns `404`, never `403`.

Balances are integer **paisa** in the customer's natural direction: positive =
the customer owes the business (receivable); negative = advance/credit.

### GET /api/customers

`customers.view` permission.

```
GET /api/customers?search=9812&isActive=true&page=1&pageSize=20
```

`search` matches **name or phone number** (case-insensitive substring).
`pageSize` is clamped to 1..100. Ordered by name ascending. Each item carries
its current khata balance flattened in:

```json
{
  "data": [
    {
      "id": 5,
      "name": "Hari Bahadur",
      "phoneNumber": "+9779812345678",
      "email": "hari@example.com",
      "addressLine": "Baneshwor, Kathmandu",
      "city": "Kathmandu",
      "district": "Kathmandu",
      "openingBalance": 50000,
      "panNumber": "123456789",
      "creditLimit": 500000,
      "notes": null,
      "isActive": true,
      "currentBalance": 105000,
      "createdAt": "2026-10-13T10:00:00Z",
      "updatedAt": "2026-10-13T10:00:00Z"
    }
  ],
  "pagination": { "page": 1, "pageSize": 20, "totalItems": 1, "totalPages": 1, "hasNext": false, "hasPrev": false }
}
```

### GET /api/customers/{id}

`customers.view`. Single `CustomerDto` (same shape as a list item).
`404` when the customer does not exist in this business.

### POST /api/customers

`customers.create`. Returns `201 Created` with the new customer and a
`Location` header.

```json
{
  "name": "Hari Bahadur",
  "phoneNumber": "+9779812345678",
  "email": "hari@example.com",
  "addressLine": "Baneshwor, Kathmandu",
  "city": "Kathmandu",
  "district": "Kathmandu",
  "openingBalance": 50000,
  "panNumber": "123456789",
  "creditLimit": 500000,
  "notes": null,
  "isActive": true
}
```

`openingBalance` and `creditLimit` are paisa (`creditLimit: null` = unlimited).
A **non-zero opening balance** immediately creates the customer's ledger account
and its first (immutable) transaction (`referenceType: "opening"`).

Validation (`400`): name required (≤200); phone matches `^\+?[\d\s-]{6,20}$`
when present; email valid when present; PAN 9 digits when present; credit limit
≥ 0; address ≤500, city/district ≤100, notes ≤1000.

### PUT /api/customers/{id}

`customers.edit`. Full replacement (same body as create). Returns the updated
`CustomerDto`. Changing `openingBalance` appends an `"adjustment"` transaction
for the difference — the ledger is **never rewritten** (the original opening
entry is untouched). `400` on validation failure, `404` when missing.

### DELETE /api/customers/{id}

`customers.edit`. Soft-deletes the customer (`204 No Content`). The ledger
account and its full transaction history are preserved. `404` when missing.

### GET /api/customers/{id}/ledger

`customers.view`.

```
GET /api/customers/5/ledger?page=1&pageSize=20
```

`pageSize` clamped to 1..100. Transactions are ordered newest first
(`transactionDate` desc, then `id` desc).

```json
{
  "summary": {
    "openingBalance": 50000,
    "totalDebit": 55000,
    "totalCredit": 0,
    "closingBalance": 105000
  },
  "data": [
    {
      "id": 12,
      "transactionType": "Debit",
      "amount": 55000,
      "balanceAfter": 105000,
      "transactionDate": "2026-10-05",
      "referenceType": "sale",
      "referenceId": 34,
      "description": "Sale #INV-00123",
      "createdAt": "2026-10-05T09:00:00Z"
    }
  ],
  "pagination": { "page": 1, "pageSize": 20, "totalItems": 1, "totalPages": 1, "hasNext": false, "hasPrev": false }
}
```

`transactionType` is serialized as a string (`"Debit"` | `"Credit"`); `amount`
is always positive and the direction is the type. For a customer, **Debit = they
owe more, Credit = they paid**. `closingBalance = opening + totalDebit −
totalCredit`. `404` when the customer does not exist in this business.

---

## 7. Supplier Endpoints

Identical to the customer endpoints, minus `creditLimit`. Permission codes are
`suppliers.view` / `suppliers.create` / `suppliers.edit`.

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/suppliers` | `search` (name/phone), `isActive`, `page`, `pageSize`; ordered by name |
| GET | `/api/suppliers/{id}` | `SupplierDto` |
| POST | `/api/suppliers` | `201`; a non-zero opening balance writes the opening ledger entry |
| PUT | `/api/suppliers/{id}` | an opening-balance change appends an adjustment entry |
| DELETE | `/api/suppliers/{id}` | soft delete, `204`; ledger history preserved |
| GET | `/api/suppliers/{id}/ledger` | same envelope as the customer ledger |

Balances are in the supplier's natural direction: positive = the business owes
the supplier (payable). In the ledger, **Credit = we owe more, Debit = we paid**;
`closingBalance = opening + totalCredit − totalDebit`.

---

## 8. Sales Endpoints

Implemented in Phase 5. Scoped to the caller's active business (JWT `bid`).
Money is integer paisa; `quantity` is the only decimal. `SaleType` and
`PaymentStatus` serialize as strings.

Payment rules (enforced, `422` on violation):

- **Cash** — `paidAmount` must equal the total.
- **Credit** — `paidAmount` must be `0`; a `customerId` is required.
- **Partial** — `0 < paidAmount < total`.

### GET /api/sales

`sales.view`. Search matches invoice number and customer name.

```
GET /api/sales?customerId=5&saleType=Credit&paymentStatus=Unpaid
    &dateFrom=2026-10-01&dateTo=2026-10-31&search=INV-000&page=1&pageSize=20
```

Items are omitted from list rows (empty array) — fetch the detail for lines.

```json
{
  "data": [
    {
      "id": 34,
      "invoiceNumber": "INV-00001",
      "customerId": 5,
      "customerName": "Hari Bahadur",
      "saleType": "Credit",
      "paymentStatus": "Unpaid",
      "saleDate": "2026-10-05",
      "subtotal": 55000,
      "discountAmount": 5000,
      "taxAmount": 0,
      "totalAmount": 50000,
      "paidAmount": 0,
      "dueAmount": 50000,
      "notes": "Deliver by Friday",
      "items": [],
      "createdAt": "2026-10-05T10:30:00Z",
      "updatedAt": "2026-10-05T10:30:00Z"
    }
  ],
  "pagination": { "page": 1, "pageSize": 20, "totalItems": 1, "totalPages": 1, "hasNext": false, "hasPrev": false }
}
```

### GET /api/sales/{id}

`sales.view`. Full sale with its line items (ordered by id). `404` when the sale
does not exist in this business.

### POST /api/sales

`sales.create`. `201 Created` + `Location`. The whole workflow runs in **one
transaction**:

1. Allocate the next per-business invoice number (`INV-00001`, `INV-00002`, …)
   unless `invoiceNumber` is supplied.
2. Insert the sale + items (product name/price snapshotted for audit).
3. Decrement stock for every line, appending immutable `Sale` stock movements
   (negative stock → `422 insufficient_stock`).
4. Append the **due** portion to the customer's khata as a **Debit**
   (`referenceType: "sale"`). A fully-paid sale writes nothing to the ledger.

```json
{
  "customerId": 5,
  "saleType": "Credit",
  "saleDate": "2026-10-08",
  "discountAmount": 0,
  "paidAmount": 0,
  "notes": "Monthly supply",
  "items": [
    { "productId": 5, "quantity": 10, "unitPrice": 11000, "discountAmount": 0, "taxRateBps": 1300 }
  ]
}
```

`unitPrice` defaults to the product's selling price and `taxRateBps` to its tax
rate when omitted. Per line: `gross = round(unitPrice × quantity)`,
`tax = round((gross − discount) × taxRateBps / 10000)`,
`lineTotal = gross − discount + tax`. Sale totals:
`totalAmount = Σgross − (ΣlineDiscount + headerDiscount) + Σtax`.

Errors: `400` (no items, quantity ≤ 0, negative price/discount, tax rate out of
range), `404` (unknown product/customer), `422` (insufficient stock, credit
without a customer, payment/type mismatch, overpayment, discount > subtotal).

### DELETE /api/sales/{id}

`sales.delete`. **Reverses** the sale rather than erasing it: stock is restored
(`ReturnIn` movements, `referenceType: "sale_reversal"`) and the khata Debit is
reversed with an equal Credit. The row is then soft-deleted (its items are kept).
`204`. `404` when missing.

---

## 9. Purchase Endpoints

Mirror of sales, with `purchase.view` / `purchase.create` / `purchase.delete`
permissions. Stock goes **up**, the due portion is a **Credit** on the supplier's
khata (we owe more), and the document number is `BILL-00001`, `BILL-00002`, …
`unitPrice` defaults to the product's **cost price**.

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/purchases` | `supplierId`, `purchaseType`, `paymentStatus`, `dateFrom`, `dateTo`, `search` (bill no./supplier), `page`, `pageSize` |
| GET | `/api/purchases/{id}` | `PurchaseDto` with items |
| POST | `/api/purchases` | atomic: bill number + stock in + supplier payable |
| DELETE | `/api/purchases/{id}` | reverses stock (`ReturnOut`, `purchase_reversal`) and the payable, then soft-deletes |

The `POST` body mirrors a sale with `supplierId`, `purchaseType`, `billNumber`
and `purchaseDate`. A credit purchase requires a `supplierId` (`422` otherwise).
Payment rules are the same as sales (`Cash`/`Credit`/`Partial`).

---

## 10. Expense Endpoints

`expenses.view` / `expenses.create` / `expenses.edit`. Amount is paisa;
`expenseDate` defaults to today.

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/expenses` | `search` (category/description/reference), `category`, `dateFrom`, `dateTo`, `page`, `pageSize` |
| GET | `/api/expenses/{id}` | `ExpenseDto` |
| POST | `/api/expenses` | `201`; `category` required, `amount > 0` |
| PUT | `/api/expenses/{id}` | full replacement |
| DELETE | `/api/expenses/{id}` | soft delete, `204` |

```json
{
  "category": "Rent",
  "amount": 250000,
  "expenseDate": "2026-10-01",
  "description": "Monthly shop rent",
  "paymentMethod": "cash",
  "reference": "RCPT-14",
  "notes": null
}
```

---

## 11. Income Endpoints

`income.view` / `income.create` / `income.edit`. Route is `/api/incomes`
(plural). Same shape as expenses, with `source` instead of `category` and
`incomeDate` instead of `expenseDate`.

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/incomes` | `search`, `source`, `dateFrom`, `dateTo`, `page`, `pageSize` |
| GET | `/api/incomes/{id}` | `IncomeDto` |
| POST | `/api/incomes` | `201`; `source` required, `amount > 0` |
| PUT | `/api/incomes/{id}` | full replacement |
| DELETE | `/api/incomes/{id}` | soft delete, `204` |

---

## 12. Payment Endpoints

Implemented in Phase 6. Scoped to the caller's active business. Money is
integer paisa. Payments are **append-only** — a mistake is corrected by
recording the opposite payment, never by editing history.

`direction` is derived from `partyType` when omitted (Customer → `In`,
Supplier → `Out`); a mismatch is `422`. Recording a payment always writes one
khata ledger entry for the **full** amount, moving the party's natural balance
down by `amount` (customer → Credit, supplier → Debit). When a sale/purchase is
linked, the applied portion also updates that document's `paidAmount`,
`dueAmount` and `paymentStatus`; any excess stays on the account as an advance
(a negative balance).

### GET /api/payments

`payments.view`. Search matches party name and reference.

```
GET /api/payments?partyType=Customer&partyId=5&direction=In
    &dateFrom=2026-10-01&dateTo=2026-10-31&search=Ram&page=1&pageSize=20
```

```json
{
  "data": [
    {
      "id": 7,
      "partyType": "Customer",
      "partyId": 5,
      "partyName": "Hari Bahadur",
      "direction": "In",
      "amount": 6000,
      "paymentDate": "2026-10-08",
      "paymentMethodId": 1,
      "methodName": "Cash",
      "reference": "RCPT-14",
      "notes": null,
      "saleId": 34,
      "saleInvoiceNumber": "INV-00001",
      "purchaseId": null,
      "purchaseBillNumber": null,
      "appliedAmount": 6000,
      "unappliedAmount": 0,
      "createdAt": "2026-10-08T10:30:00Z"
    }
  ],
  "pagination": { "page": 1, "pageSize": 20, "totalItems": 1, "totalPages": 1, "hasNext": false, "hasPrev": false }
}
```

### GET /api/payments/summary

`payments.view`. Receivable/payable position across all parties. Advances are
negative balances (money already held / overpaid).

```json
{
  "totalReceivable": 40000,
  "totalPayable": 6000,
  "customerAdvances": 6000,
  "supplierAdvances": 0,
  "receivableParties": 2,
  "payableParties": 1
}
```

### GET /api/payments/{id}

`payments.view`. `404` when the payment does not exist in this business.

### POST /api/payments

`payments.create`. `201 Created` + `Location`.

```json
{
  "partyType": "Customer",
  "partyId": 5,
  "amount": 6000,
  "paymentDate": "2026-10-08",
  "paymentMethodId": 1,
  "reference": "RCPT-14",
  "notes": "Partial payment",
  "saleId": 34
}
```

`paymentMethodId`, `methodCode` and `saleId`/`purchaseId` are optional. With no
method given the business default is used. Errors: `400` (amount ≤ 0, no party),
`404` (unknown party / method / document), `422` (direction mismatch, a sale
linked to a different customer, a purchase linked to a different supplier,
provider failure).

### Payment methods

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/payment-methods` | `payment_methods.view`; plain array (not paged), default first then by name; `?isActive=` |
| GET | `/api/payment-methods/{id}` | `payment_methods.view` |
| POST | `/api/payment-methods` | `payment_methods.manage`; `409` on a duplicate name |
| PUT | `/api/payment-methods/{id}` | `payment_methods.manage`; setting `isDefault` clears the others |
| DELETE | `/api/payment-methods/{id}` | `payment_methods.manage`; soft delete, `422` if it is the last method |

```json
{ "id": 1, "name": "Cash", "code": "cash", "description": null, "isActive": true, "isDefault": true }
```

`code` selects the payment provider (`IPaymentProvider`): `cash` settles
immediately; any code without an integration resolves to the manual (offline)
provider — eSewa/Khalti/Fonepay will plug in here later. Five methods (Cash,
Bank Transfer, eSewa, Khalti, Cheque) are seeded for every new business, with
Cash as the default.

---

## 13. Invoice Endpoints

Implemented in Phase 7. Scoped to the caller's active business. Money is
integer paisa.

Invoices share the business's single `INV-#####` numbering series with sales —
the same `document_sequence` row — so a number is never issued twice. An invoice
is either **standalone** (allocating the next number) or **generated from a
sale** (copying its lines and reusing its number, so the printed document
matches the sale). Only **Draft** invoices can be edited.

### GET /api/invoices

`invoices.view`. Search matches invoice number and customer name.

```
GET /api/invoices?customerId=5&status=Draft&dateFrom=2026-10-01&dateTo=2026-10-31
    &search=INV-000&page=1&pageSize=20
```

```json
{
  "data": [
    {
      "id": 1,
      "invoiceNumber": "INV-00001",
      "customerId": 5,
      "customerName": "Hari Bahadur",
      "saleId": 34,
      "saleInvoiceNumber": "INV-00001",
      "status": "Draft",
      "issueDate": "2026-10-14",
      "dueDate": "2026-11-13",
      "subtotal": 220000,
      "discountAmount": 5000,
      "taxAmount": 27950,
      "totalAmount": 242950,
      "notes": null,
      "terms": null,
      "hasPdf": false,
      "pdfGeneratedAt": null,
      "items": [],
      "createdAt": "2026-10-14T08:00:00Z",
      "updatedAt": "2026-10-14T08:00:00Z"
    }
  ],
  "pagination": { "page": 1, "pageSize": 20, "totalItems": 1, "totalPages": 1, "hasNext": false, "hasPrev": false }
}
```

Items are omitted from list rows (empty array) — fetch the detail for the lines.

### GET /api/invoices/{id}

`invoices.view`. Full invoice with its line items. `404` when it does not exist
in this business.

### GET /api/invoices/{id}/pdf

`invoices.view`. Renders the invoice with QuestPDF, caches it in file storage and
returns `application/pdf` with a `<invoiceNumber>.pdf` filename. `hasPdf` and
`pdfGeneratedAt` are updated on the invoice.

### POST /api/invoices

`invoices.create`. `201 Created` + `Location`.

Standalone:

```json
{
  "customerId": 5,
  "issueDate": "2026-10-14",
  "dueDate": "2026-11-13",
  "discountAmount": 0,
  "notes": "Deliver before Friday",
  "terms": "Payment due within 30 days",
  "items": [
    { "description": "Basmati Rice 5kg", "quantity": 2, "unitPrice": 110000, "discountAmount": 5000, "taxRateBps": 1300 },
    { "description": "Delivery charge", "quantity": 1, "unitPrice": 5000 }
  ]
}
```

From a sale (omit `items` — the lines and number come from the sale):

```json
{ "saleId": 34 }
```

Per line: `gross = round(unitPrice × quantity)`,
`tax = round((gross − discount) × taxRateBps / 10000)`,
`lineTotal = gross − discount + tax`. `taxRateBps` defaults to the product's tax
rate when the line references a `productId`, and `description` may be omitted
when `productId` is given (the product name is used).

Errors: `400` (no items and no saleId, quantity ≤ 0, negative price/discount,
tax out of range), `404` (unknown customer/product/sale), `409` (an invoice for
that sale already exists).

### PUT /api/invoices/{id}

`invoices.edit`. Full replacement of the lines; the cached PDF is invalidated.
`422` when the invoice is not a **Draft** (`not_editable`).

### DELETE /api/invoices/{id}

`invoices.edit`. Soft delete, `204`.

---

## 14. Quotation Endpoints

Implemented in Phase 7. Quotations are commercial offers — they never move stock
or the khata. They have their own `QT-#####` numbering series.

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/quotations` | `quotations.view`; `customerId`, `status`, `dateFrom`, `dateTo`, `search` (quote no./customer), `page`, `pageSize` |
| GET | `/api/quotations/{id}` | full quotation with items |
| GET | `/api/quotations/{id}/pdf` | `application/pdf`, `<quoteNumber>.pdf` |
| POST | `/api/quotations` | `quotations.create`; same body as a standalone invoice, with `validUntil` |
| PUT | `/api/quotations/{id}` | `quotations.edit`; `422` once converted (`already_converted`) |
| DELETE | `/api/quotations/{id}` | `quotations.edit`; soft delete, `204` |
| POST | `/api/quotations/{id}/convert` | `quotations.edit` **and** `sales.create`; creates a real sale and returns it |

`QuotationDto` mirrors `InvoiceDto` with `quoteNumber`, `validUntil`, `status`
(`Draft` | `Sent` | `Accepted` | `Rejected` | `Expired`) and `convertedSaleId`.

### POST /api/quotations/{id}/convert

```json
{ "saleType": "Credit", "paidAmount": 0, "saleDate": null, "notes": null }
```

Runs the full sale workflow (stock movements, khata entry, invoice number) using
the quotation's lines, then marks the quotation `Accepted` and links
`convertedSaleId`. `201 Created` with the resulting `SaleDto`.

Errors: `422` when already converted, when the status is `Rejected`/`Expired`,
when any line is free text (no `productId` — a sale needs real products), or when
a non-cash conversion has no customer.

---

## 15. Report Endpoints

Implemented in Phase 8. Every endpoint is scoped to the caller's active
business. `dateFrom`/`dateTo` are **inclusive** AD dates and default to the
current month. `dateTo` must be on or after `dateFrom`, the span may not exceed
**366 days**, and `groupBy` must be `day`, `week` or `month` (422 otherwise).

Money is integer paisa. Revenue is net of discounts and **excludes VAT** (tax is
collected on the government's behalf). Cost of goods uses each product's
**current** cost price — the app does not snapshot cost at sale time.

### GET /api/reports/dashboard

`reports.view`.

```json
{
  "asOf": "2026-10-14",
  "todaySales": { "count": 1, "subtotal": 20000, "discount": 0, "tax": 2600, "total": 22600, "paid": 0, "due": 22600 },
  "monthSales": { "count": 1, "subtotal": 20000, "discount": 0, "tax": 2600, "total": 22600, "paid": 0, "due": 22600 },
  "todayPurchases": 22600,
  "todayExpenses": 3000,
  "todayIncome": 1000,
  "todayGrossProfit": 8000,
  "todayNetProfit": 6000,
  "monthPurchases": 22600,
  "monthExpenses": 3000,
  "monthIncome": 1000,
  "monthGrossProfit": 8000,
  "monthNetProfit": 6000,
  "totalReceivable": 22600,
  "totalPayable": 22600,
  "customerAdvances": 0,
  "supplierAdvances": 0,
  "stockCostValue": 318000,
  "stockRetailValue": 530000,
  "lowStockCount": 0,
  "productCount": 1,
  "customerCount": 1,
  "trend": [
    { "date": "2026-10-01", "sales": 0, "costOfGoods": 0, "grossProfit": 0, "purchases": 0, "expenses": 0, "income": 0, "netProfit": 0 }
  ],
  "topProducts": [ { "id": 1, "name": "Basmati Rice", "amount": 22600, "quantity": 2, "count": 1 } ],
  "topCustomers": [ { "id": 1, "name": "Hari Bahadur", "amount": 22600, "quantity": 0, "count": 1 } ]
}
```

`trend` is the last **14 days**, one `TrendPointDto` per day (shown here
abbreviated to one entry).

### GET /api/reports/sales

`reports.view`. `?dateFrom=&dateTo=&groupBy=day&top=10`

```json
{
  "dateFrom": "2026-10-01", "dateTo": "2026-10-31", "groupBy": "day",
  "totals": { "count": 3, "subtotal": 45000, "discount": 0, "tax": 5850, "total": 50850, "paid": 10000, "due": 40850 },
  "series": [ { "date": "2026-10-01", "sales": 15000, "costOfGoods": 9000, "grossProfit": 6000,
                "purchases": 0, "expenses": 0, "income": 0, "netProfit": 6000 } ],
  "topProducts": [ { "id": 1, "name": "Basmati Rice", "amount": 45000, "quantity": 3, "count": 2 } ],
  "topCustomers": [ { "id": 5, "name": "Hari Bahadur", "amount": 45000, "quantity": 0, "count": 3 } ]
}
```

`series` has one `TrendPointDto` **per bucket** covering the whole range (empty
days included, so charts have no gaps). Buckets start on Mondays for `week` and
on the 1st of the month for `month`.

### GET /api/reports/purchases

`reports.view`. → `{ dateFrom, dateTo, groupBy, totals, series, topSuppliers }`

### GET /api/reports/expenses

`reports.view`. → `{ dateFrom, dateTo, groupBy, total, count, byCategory, series }`

### GET /api/reports/income

`reports.view`. → `{ dateFrom, dateTo, groupBy, total, count, bySource, series }`

`byCategory` / `bySource` are `CategoryAmountDto` (`category`, `amount`,
`count`), ordered largest first.

### GET /api/reports/profit-loss

`reports.view`.

```json
{
  "dateFrom": "2026-10-01", "dateTo": "2026-10-31",
  "revenue": 20000, "costOfGoods": 12000, "grossProfit": 8000,
  "otherIncome": 1000, "expenses": 3000, "netProfit": 6000,
  "salesTaxCollected": 2600,
  "expensesByCategory": [ { "category": "Rent", "amount": 3000, "count": 1 } ]
}
```

### GET /api/reports/stock

`reports.view`. `?lowStockOnly=false&search=` (search matches the product name).

```json
{
  "totalCostValue": 318000, "totalRetailValue": 530000, "potentialMargin": 212000,
  "productCount": 1, "lowStockCount": 0,
  "items": [
    { "productId": 1, "name": "Basmati Rice", "categoryName": "General", "unitShortName": "kg",
      "quantity": 53, "costPrice": 6000, "sellingPrice": 10000,
      "costValue": 318000, "retailValue": 530000, "isLowStock": false }
  ]
}
```

Products without a stock row count as zero stock. `lowStockCount` covers the
**whole** catalogue even when the list is filtered by `lowStockOnly`.

### GET /api/reports/receivable-payable

`reports.view`.

```json
{
  "totalReceivable": 22600, "totalPayable": 22600,
  "customerAdvances": 0, "supplierAdvances": 0,
  "receivables": [ { "partyId": 1, "name": "Hari Bahadur", "phoneNumber": "+97798…",
                    "balance": 22600, "openDocuments": 1 } ],
  "payables": [ { "partyId": 2, "name": "Himal Distributors", "phoneNumber": null,
                  "balance": 22600, "openDocuments": 1 } ]
}
```

### GET /api/reports/export

`reports.export`.
`?type=sales|purchases|expenses|income|profit-loss|stock&dateFrom=&dateTo=`

Returns `text/csv` (UTF-8 **with a BOM** so Excel opens Nepali text correctly)
and a `<type>-<from>_<to>.csv` filename. Fields containing commas or quotes are
properly escaped. An unknown `type` is 422.

---

## 16. Notification Endpoints

Per-user in-app feed, FCM device registration and push settings. Categories:
`Reminder`, `LowStock`, `PaymentDue`, `Backup`, `System`.

### GET /api/notifications

Query: `?unreadOnly=true&category=Reminder&page=1&pageSize=50`.
Returns `PagedResult<NotificationDto>` — `{ data: [...], pagination: {...} }`.

```json
{
  "id": 4, "title": "Overdue bill", "body": "Reminder is due.",
  "category": "Reminder", "referenceType": "reminder", "referenceId": 6,
  "isRead": false, "readAt": null, "createdAt": "2026-10-15T10:44:53"
}
```

Timestamps in responses are **Nepal local (UTC+05:45)**, naive.

### GET /api/notifications/unread-count

```json
{ "count": 3 }
```

### PUT /api/notifications/{id}/read

Marks one notification read. `200`. `404` if it is not yours.

### PUT /api/notifications/read-all

Marks every unread notification read. `200`.

### DELETE /api/notifications/{id}

Soft-deletes a notification. `204`.

### GET /api/notifications/devices

Lists the caller's registered devices.

### POST /api/notifications/devices

Registers (or refreshes) an FCM device token. Idempotent per token: the same
token sent again updates its business/user/platform instead of duplicating.

```json
{ "token": "fcm-token-string", "platform": "Android", "deviceName": "Ram's phone" }
```

`platform` is one of `Android` | `Ios` | `Web`. `400` on an empty token.

### DELETE /api/notifications/devices/{id}

Unregisters a device. `204`.

### GET /api/notifications/settings

```json
{
  "pushEnabled": true, "reminderEnabled": true, "lowStockEnabled": true,
  "paymentDueEnabled": true, "backupEnabled": true, "systemEnabled": true
}
```

All categories default to enabled.

### PUT /api/notifications/settings

Same shape as the GET. Persists per user per business.

---

## 17. Reminder Endpoints

A dated to-do; a due reminder raises a notification. `status` is
`Pending` | `Done` | `Dismissed`; `repeat` is `None` | `Daily` | `Weekly` |
`Monthly` | `Yearly`. `dueAt` is sent in **Nepal local (UTC+05:45)** and stored
UTC internally.

### GET /api/reminders

Query: `?status=Pending&page=1&pageSize=50`. `PagedResult<ReminderDto>`.

### POST /api/reminders

```json
{
  "title": "Weekly report", "notes": "Call Ram",
  "dueAt": "2026-10-15T15:41", "repeat": "Weekly",
  "relatedEntityType": "customer", "relatedEntityId": 12
}
```

`201` with the created reminder, initially `Pending`. `400` on an empty title.
Repeating reminders must carry a `repeat` other than `None`.

### GET /api/reminders/{id}

`200` or `404` for another business's reminder.

### PUT /api/reminders/{id}

Updates title/notes/dueAt/repeat. A non-`Pending` reminder is **reopened to
`Pending`** by an update — rescheduling implies it is live again.

### POST /api/reminders/{id}/complete

Marks it `Done` and stamps `completedAt`.

### POST /api/reminders/{id}/dismiss

Marks it `Dismissed` without completing it.

### DELETE /api/reminders/{id}

Soft-deletes. `204`.

### POST /api/reminders/process-due

The scheduling engine, deliberately a plain endpoint rather than a Hangfire or
Quartz dependency: idempotent (a reminder fires once) and bounded to 200 rows
per call, so a client, a cron job, or a future scheduler can drive it.

```json
{ "fired": 1 }
```

Each due reminder raises a notification for its owner and is then either
completed (one-shot) or advanced to its next **future** occurrence (repeating —
so a weekly reminder three weeks overdue lands on the next upcoming date, not
three timestamps in the past).

---

## 18. Backup Endpoints

Full JSON snapshot of the active business, and a merge-only restore.

### GET /api/backup/export

Returns a JSON file download (`Content-Disposition: attachment;
filename="khata-backup-<id>-<timestamp>.json"`). The payload is a **lossless
mirror** of the document tables — soft-deleted rows included, so history
survives — plus `stock` for each product.

Derived ledgers (ledger accounts/entries, stock movements) are **not**
included: restoring documents without their derived entries would leave caches
and ledgers disagreeing. A restore reproduces the documents; derived ledgers
are rebuilt by replaying business operations.

```json
{
  "version": 1, "businessId": 3, "businessName": "Demo Shop",
  "exportedAt": "2026-10-15T16:20:00",
  "units": [...], "categories": [...], "products": [...],
  "customers": [...], "suppliers": [...], "paymentMethods": [...],
  "sales": [...], "purchases": [...], "expenses": [...], "incomes": [...],
  "payments": [...], "invoices": [...], "quotations": [...]
}
```

### POST /api/backup/restore

Body: the exported document. Returns `BackupRestoreResultDto` with per-table
inserted/skipped counts.

**Merge semantics — never overwrite.** A snapshot restores *into* a business;
`400` if `version` is newer than the server's.

- A row the target already has is **skipped**. Money rows are immutable, so
  rewriting them would corrupt the ledger.
- Payload ids already owned by another business are **re-homed** onto free ids
  and every reference is remapped, so nothing is lost and nothing collides.
- Seeded lookups (`unit`, `payment_method`) are matched **by name** and reused,
  since every business starts with its own defaults.
- Repeat restores are idempotent via the `backup_restore_entry` id ledger,
  which records source id → written id per backup file.

```json
{
  "businessId": 3,
  "productsInserted": 12, "productsSkipped": 0,
  "customersInserted": 4, "customersSkipped": 0,
  "suppliersInserted": 2, "suppliersSkipped": 0,
  "salesInserted": 30, "salesSkipped": 0,
  "purchasesInserted": 8, "purchasesSkipped": 0,
  "expensesInserted": 5, "expensesSkipped": 0,
  "incomesInserted": 3, "incomesSkipped": 0,
  "paymentsInserted": 40, "paymentsSkipped": 0,
  "invoicesInserted": 10, "invoicesSkipped": 0,
  "quotationsInserted": 6, "quotationsSkipped": 0,
  "paymentMethodsInserted": 0, "paymentMethodsMatched": 5,
  "unitsInserted": 2, "unitsMatched": 4
}
```

---

## 19. Import Endpoints

CSV import for the onboarding case: a shop that already keeps its catalog in
Excel. Products and customers are separate surfaces with separate permissions.

Two rules hold for both:

- **All or nothing.** A file with one invalid row is refused (`422`) and writes
  nothing; the response lists the rows to fix with their line numbers.
- **Never overwrite.** A row that already exists is skipped, so re-running the
  same file is safe. A product is identified by its SKU when the row has one,
  otherwise by its name; a customer by name + phone.

Rows are validated with the **same FluentValidation validators the REST
endpoints use**, so an import can never accept a row `POST /api/products` would
reject.

### GET /api/import/products/template · /api/import/customers/template

`import.products` / `import.customers`. Header-only CSV download (UTF-8 with
BOM, so Excel opens Devanagari headers correctly).

### POST /api/import/{entity}/preview

Dry run. Body `{ "csv": "<the whole file>" }`. Returns `ImportPreviewDto`:

```json
{
  "entity": "products", "totalRows": 42, "validRows": 40,
  "duplicateRows": 1, "invalidRows": 1,
  "columns": ["name", "sku", "sellingPrice"],
  "ignoredColumns": ["colour"],
  "issues": [{ "row": 17, "column": "sellingPrice", "message": "'12x' is not a valid amount." }]
}
```

`row` is the line number in the file (header = row 1), so it matches Excel.

### POST /api/import/{entity}

Body as above. `200` with `ImportResultDto` (`created`, `skipped`), or `422`
with the same `ImportPreviewDto` when any row is invalid.

**Header aliases.** Lookup ignores case, spaces and underscores, and accepts the
obvious synonyms — so `Product Name`, `cost_price`, `Cost`, `Qty` and `VAT` all
work. Nepali headers (`नाम`, `मूल्य`, `इकाई`, `फोन`, `जिल्ला`) work too.

**Values.**

| Column | Accepted |
|--------|----------|
| money (`costPrice`, `sellingPrice`, `openingBalance`, …) | rupees: `1234.5`, `1,234.50`, `Rs 1,234.50`, `रु 1200` → integer paisa |
| `taxRate` | percentage: `13` or `13%` → 1300 bps |
| `openingQuantity`, `minQuantity` | decimal, invariant (`.` separator) |
| `unit` | matched against existing unit names / short names; an unknown unit is a row error |
| `category` | matched, and **created** if missing (a category is only a grouping label) |

Limits: 5,000 rows and 2,000,000 characters per file.

---

## 20. Sync Endpoints


Implemented in Phase 9. Delta synchronisation for offline-first clients.

- **Pull** returns everything changed in the active business since a cursor (the
  previous response's `serverTime`), so a client can refresh a local cache.
- **Push** applies a batch of client-queued writes. Each operation carries a
  client-generated `operationId` (idempotency) and, for updates, a
  `baseUpdatedAt` (optimistic concurrency).
- Every write is routed to the same service the online endpoint uses, so
  validation, document numbering, stock and ledger rules are identical online
  and offline. Payloads are validated with the same FluentValidation validators
  — an offline write cannot skip a rule.

### GET /api/sync/pull

`sync.use`. `?since=<ISO8601 cursor>&limit=500` (max 1000).

```json
{
  "serverTime": "2026-10-14T11:08:13Z",
  "since": null,
  "changes": [
    {
      "entityType": "customer",
      "entityId": 7,
      "changeType": "upsert",
      "changedAt": "2026-10-14T11:07:55.1234567Z",
      "payload": {
        "id": 7, "name": "Hari Bahadur", "phoneNumber": null,
        "addressLine": null, "panNumber": null, "openingBalance": 0,
        "notes": null, "isActive": true
      }
    },
    {
      "entityType": "customer", "entityId": 7, "changeType": "deleted",
      "changedAt": "2026-10-14T11:08:13.0591280Z", "payload": { "…": "…" }
    }
  ],
  "hasMore": false
}
```

`entityType` is `unit`, `category`, `product`, `stock`, `customer`, `supplier`,
`sale`, `purchase`, `expense`, `income` or `payment`. `changeType` is `upsert`
for live rows and `deleted` for soft-deleted ones (the client should drop them
from its cache).

**Cursor semantics.** The database stores whole-second precision, so the server
pulls the cursor back one full second. A row changed in the same second as the
cursor may therefore legitimately repeat in the next pull — applying an upsert
twice is idempotent, whereas *missing* a change is data loss, so the protocol
always errs toward repeating. Omit `since` for a full first sync.

### POST /api/sync/push

`sync.use`. Max 200 operations per call.

```json
{
  "operations": [
    {
      "operationId": "550e8400-e29b-41d4-a716-446655440000",
      "entityType": "customer",
      "operation": "create",
      "entityId": 0,
      "baseUpdatedAt": null,
      "payload": { "name": "Hari Bahadur" }
    },
    {
      "operationId": "…",
      "entityType": "customer",
      "operation": "update",
      "entityId": 7,
      "baseUpdatedAt": "2026-10-14T10:00:00Z",
      "payload": { "name": "New name" }
    }
  ]
}
```

Supported entity/operation pairs: `customer`, `supplier`, `product`, `expense`
and `income` support `create` / `update` / `delete`; `sale` supports `create`
only (updating or deleting a sale goes through the online flow so its stock
movements and ledger entries stay consistent). Anything else is `rejected`.

```json
{
  "serverTime": "2026-10-14T11:08:14Z",
  "applied": 1, "conflicts": 1, "rejected": 0,
  "results": [
    {
      "operationId": "550e8400-e29b-41d4-a716-446655440000",
      "status": "applied",
      "entityId": 12,
      "version": "2026-10-14T11:08:13.7856037Z",
      "error": null
    },
    {
      "operationId": "…",
      "status": "conflict",
      "entityId": 7,
      "version": "2026-10-14T11:08:12.5629251Z",
      "error": "The record changed on the server after this edit was made offline."
    },
    { "operationId": "…", "status": "rejected", "entityId": null,
      "version": null, "error": "Name: Customer name is required." }
  ]
}
```

Per-operation `status`:

| status | meaning |
|--------|---------|
| `applied` | done. `entityId` is the server row, `version` its new `UpdatedAt`. |
| `duplicate` | this `operationId` was already processed — safe to retry. |
| `conflict` | the server row is newer than `baseUpdatedAt`; never auto-overwritten. |
| `rejected` | validation or a business rule failed; `error` says why. |

The whole batch is applied per operation — one bad operation does not roll back
the others. Idempotency is recorded in a `sync_operation` table keyed on
`(BusinessId, OperationId)`.

### GET /api/sync/status

`sync.view`.

```json
{ "serverTime": "2026-10-14T11:08:13Z", "storedOperations": 9, "pendingConflicts": 1 }
```

---

## 21. Rate Limiting

| Endpoint Group | Limit |
|----------------|-------|
| Auth (login, register) | 10 requests / minute per IP |
| Sync push | 60 requests / minute per user |
| General API | 200 requests / minute per user |

Rate-limited responses return 429 with `Retry-After` header.

---

## 22. API Versioning

Versioning via URL prefix: `/api/v1/...`. Breaking changes require a new version.
Non-breaking changes (adding fields, endpoints) do not require a version bump.

Current version: **v1** (implicit in `/api/` prefix).
