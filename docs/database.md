# Database Schema

> Complete PostgreSQL schema design for Nepal Digital Khata.
> All monetary values use `numeric(18,2)` (server) / paisa integer (API + local).
> Every business-scoped entity carries `BusinessId` for tenant isolation.

---

## 1. Conventions

### 1.1 Naming

| Convention | Example |
|------------|---------|
| Table names | `snake_case`, singular: `sale`, `sale_item` |
| Column names | `snake_case`: `created_at`, `business_id` |
| Primary keys | `id` (bigint identity) |
| Foreign keys | `{referenced_table}_id`: `customer_id`, `business_id` |
| Join tables | `{a}_{b}`: `role_permission` |
| Indexes | `ix_{table}_{columns}`: `ix_sale_business_id_date` |
| Unique constraints | `uq_{table}_{columns}`: `uq_business_name_owner_id` |

### 1.2 Common Audit Columns

Every table includes:

```sql
created_at  timestamptz NOT NULL DEFAULT now(),
updated_at  timestamptz NOT NULL DEFAULT now(),
created_by  bigint     NOT NULL,   -- FK to app_user.id
updated_by  bigint     NOT NULL,   -- FK to app_user.id
```

Tables supporting soft delete also include:

```sql
deleted_at  timestamptz NULL,       -- soft delete timestamp
```

If `deleted_at IS NOT NULL`, the record is considered deleted. EF Core global
query filters automatically exclude soft-deleted rows.

### 1.3 ID Strategy

- **Server**: `bigint` identity (PostgreSQL `identity always`)
- **Client**: UUID (generated on device, stored as `local_id` in Drift)
- **Sync**: Client sends `localId`; server returns `id` (bigint). Client stores `server_id`.

### 1.4 Money Type

```sql
amount  numeric(18,2) NOT NULL DEFAULT 0
```

In API DTOs and local SQLite, amounts are stored as `INTEGER` paisa
(`int64`). The API layer converts paisa ↔ numeric on the way in/out.

---

## 2. Entity Relationship Overview

```
app_user ──┬── business_member ── business ──┐
            │                                    ├── product_category ── product ── stock
            │                                    ├── unit
            │                                    ├── customer ──┐
            │                                    ├── supplier ──┤
            │                                    │              ├── sale ── sale_item
            │                                    │              ├── purchase ── purchase_item
            │                                    │              ├── ledger_account ── ledger_transaction
            │                                    │              ├── payment ── payment_method
            │                                    │              ├── invoice ── invoice_item
            │                                    │              ├── quotation ── quotation_item
            │                                    │              ├── expense
            │                                    │              ├── income
            │                                    │              ├── business_bank_account
            │                                    │              ├── reminder
            │                                    │              ├── notification
            │                                    │              ├── device_registration
            │                                    │              ├── notification_settings
            │                                    │              ├── backup_restore_entry
            │                                    │              └── attachment
            │                                    └── audit_log
            └── role ── role_permission ── permission
```

---

## 3. Auth & Identity Tables

### 3.1 app_user

```sql
CREATE TABLE app_user (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email           varchar(256) NOT NULL,
    email_confirmed boolean      NOT NULL DEFAULT false,
    phone_number    varchar(20),
    phone_confirmed boolean      NOT NULL DEFAULT false,
    full_name       varchar(200) NOT NULL,
    password_hash   varchar(512) NOT NULL,          -- ASP.NET Identity hashed
    security_stamp  varchar(64),
    is_active       boolean      NOT NULL DEFAULT true,
    profile_image_url varchar(512),
    locale          varchar(10)  NOT NULL DEFAULT 'ne',  -- 'ne' | 'en'
    timezone        varchar(50)  NOT NULL DEFAULT 'Asia/Kathmandu',
    -- ASP.NET Identity standard columns
    lockout_end     timestamptz,
    lockout_enabled boolean      NOT NULL DEFAULT false,
    access_failed_count  integer NOT NULL DEFAULT 0,
    -- Audit
    created_at      timestamptz  NOT NULL DEFAULT now(),
    updated_at      timestamptz  NOT NULL DEFAULT now(),
    created_by      bigint       NOT NULL,
    updated_by      bigint       NOT NULL,
    CONSTRAINT uq_app_user_email UNIQUE (email)
);
CREATE INDEX ix_app_user_email ON app_user(email);
```

> ASP.NET Identity manages `password_hash`, `security_stamp`, `lockout_*`
> columns internally. The columns above are co-located in a single table
> for simplicity. EF Core Identity configuration maps them appropriately.

### 3.2 app_role

```sql
CREATE TABLE app_role (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        varchar(100) NOT NULL,         -- 'Owner', 'Admin', 'Manager', etc.
    normal_name varchar(100) NOT NULL,         -- upper-case for lookup
    description varchar(500),
    is_system   boolean NOT NULL DEFAULT false, -- system roles cannot be deleted
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    created_by  bigint NOT NULL,
    updated_by  bigint NOT NULL,
    CONSTRAINT uq_app_role_normal_name UNIQUE (normal_name)
);
```

### 3.3 permission

```sql
CREATE TABLE permission (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code        varchar(100) NOT NULL,   -- 'sales.create', 'inventory.adjust'
    description varchar(500),
    category    varchar(50) NOT NULL,    -- 'sales', 'purchase', 'inventory', etc.
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    created_by  bigint NOT NULL,
    updated_by  bigint NOT NULL,
    CONSTRAINT uq_permission_code UNIQUE (code)
);
```

### 3.4 role_permission (join)

```sql
CREATE TABLE role_permission (
    role_id       bigint NOT NULL REFERENCES app_role(id) ON DELETE CASCADE,
    permission_id bigint NOT NULL REFERENCES permission(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);
```

---

## 4. Business Tables

### 4.1 business

```sql
CREATE TABLE business (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            varchar(200) NOT NULL,
    type            varchar(50),            -- 'Retail', 'Wholesale', 'Service', etc.
    pan_number      varchar(50),            -- PAN/VAT
    phone_number    varchar(20),
    email           varchar(256),
    address_line    varchar(500),
    city            varchar(100),
    district        varchar(100),
    province       varchar(100),
    ward_number     varchar(20),
    logo_url        varchar(512),
    currency        varchar(10) NOT NULL DEFAULT 'NPR',
    fiscal_year_start  date,               -- for reporting periods
    is_active       boolean NOT NULL DEFAULT true,
    deleted_at      timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL,
    updated_by      bigint NOT NULL,
    CONSTRAINT uq_business_name_owner UNIQUE (name, created_by)
);
CREATE INDEX ix_business_deleted ON business(deleted_at) WHERE deleted_at IS NULL;
```

### 4.2 business_member

Links users to businesses with a role. A user can be a member of multiple businesses.

```sql
CREATE TABLE business_member (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id bigint NOT NULL REFERENCES business(id),
    user_id     bigint NOT NULL REFERENCES app_user(id),
    role_id     bigint NOT NULL REFERENCES app_role(id),
    is_active   boolean NOT NULL DEFAULT true,
    invited_at  timestamptz,
    joined_at   timestamptz,
    deleted_at  timestamptz,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    created_by  bigint NOT NULL,
    updated_by  bigint NOT NULL,
    CONSTRAINT uq_business_member_business_user UNIQUE (business_id, user_id)
);
CREATE INDEX ix_business_member_user ON business_member(user_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_business_member_business ON business_member(business_id) WHERE deleted_at IS NULL;
```

### 4.3 business_bank_account

```sql
CREATE TABLE business_bank_account (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id     bigint NOT NULL REFERENCES business(id),
    bank_name       varchar(200) NOT NULL,
    account_name    varchar(200) NOT NULL,
    account_number  varchar(50) NOT NULL,
    branch          varchar(200),
    is_default      boolean NOT NULL DEFAULT false,
    is_active       boolean NOT NULL DEFAULT true,
    deleted_at      timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL,
    updated_by      bigint NOT NULL
);
CREATE INDEX ix_business_bank_account_business ON business_bank_account(business_id) WHERE deleted_at IS NULL;
```

---

## 5. Product & Inventory Tables

### 5.1 product_category

```sql
CREATE TABLE product_category (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id  bigint NOT NULL REFERENCES business(id),
    name         varchar(200) NOT NULL,
    description  text,
    parent_id    bigint REFERENCES product_category(id),  -- nested categories
    is_active    boolean NOT NULL DEFAULT true,
    deleted_at   timestamptz,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    created_by   bigint NOT NULL,
    updated_by   bigint NOT NULL
);
CREATE INDEX ix_product_category_business ON product_category(business_id) WHERE deleted_at IS NULL;
```

### 5.2 unit

```sql
CREATE TABLE unit (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id  bigint NOT NULL REFERENCES business(id),
    name         varchar(50) NOT NULL,        -- 'pcs', 'kg', 'box', 'dozen'
    short_name   varchar(10) NOT NULL,       -- 'pc', 'kg'
    is_active    boolean NOT NULL DEFAULT true,
    deleted_at   timestamptz,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    created_by   bigint NOT NULL,
    updated_by   bigint NOT NULL,
    CONSTRAINT uq_unit_business_name UNIQUE (business_id, name)
);
```

### 5.3 product

```sql
CREATE TABLE product (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id         bigint NOT NULL REFERENCES business(id),
    category_id         bigint REFERENCES product_category(id),
    unit_id             bigint REFERENCES unit(id),
    name                varchar(200) NOT NULL,
    sku                 varchar(100),
    barcode             varchar(100),
    description         text,
    cost_price          numeric(18,2) NOT NULL DEFAULT 0,
    selling_price       numeric(18,2) NOT NULL DEFAULT 0,
    wholesale_price     numeric(18,2),
    tax_rate            numeric(5,2)  NOT NULL DEFAULT 0,  -- percentage
    image_url           varchar(512),
    is_active           boolean NOT NULL DEFAULT true,
    deleted_at          timestamptz,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    created_by          bigint NOT NULL,
    updated_by          bigint NOT NULL
);
CREATE INDEX ix_product_business ON product(business_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_product_business_name ON product(business_id, name) WHERE deleted_at IS NULL;
CREATE INDEX ix_product_sku ON product(business_id, sku) WHERE deleted_at IS NULL;
CREATE INDEX ix_product_barcode ON product(business_id, barcode) WHERE deleted_at IS NULL;
```

### 5.4 stock

Current stock level per product. Derived from stock movements but cached for
fast reads. Updated within the same transaction as stock movements.

```sql
CREATE TABLE stock (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id     bigint NOT NULL REFERENCES business(id),
    product_id      bigint NOT NULL REFERENCES product(id),
    quantity        numeric(18,3) NOT NULL DEFAULT 0,  -- supports fractional (kg)
    min_quantity    numeric(18,3) NOT NULL DEFAULT 0,  -- low-stock threshold
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_stock_business_product UNIQUE (business_id, product_id)
);
CREATE INDEX ix_stock_low ON stock(business_id, quantity, min_quantity)
    WHERE quantity <= min_quantity;
```

### 5.5 stock_movement

Append-only log of every stock change. Never updated or deleted.

```sql
CREATE TABLE stock_movement (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id     bigint NOT NULL REFERENCES business(id),
    product_id      bigint NOT NULL REFERENCES product(id),
    movement_type   varchar(20) NOT NULL,  -- 'purchase', 'sale', 'return_in', 'return_out', 'adjustment_in', 'adjustment_out', 'opening'
    quantity        numeric(18,3) NOT NULL,  -- positive = in, negative = out
    balance_after   numeric(18,3) NOT NULL,  -- stock after this movement
    reference_type  varchar(30),    -- 'sale', 'purchase', 'adjustment'
    reference_id    bigint,         -- FK to the referencing record
    notes           text,
    movement_date   date NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL
    -- No updated_at, no deleted_at: this is an immutable ledger
);
CREATE INDEX ix_stock_movement_product ON stock_movement(product_id, movement_date);
CREATE INDEX ix_stock_movement_business ON stock_movement(business_id, movement_date);
CREATE INDEX ix_stock_movement_reference ON stock_movement(reference_type, reference_id);
```

---

## 6. Customer & Supplier Tables

### 6.1 customer

```sql
CREATE TABLE customer (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id       bigint NOT NULL REFERENCES business(id),
    name              varchar(200) NOT NULL,
    phone_number      varchar(20),
    email             varchar(256),
    address_line      varchar(500),
    city              varchar(100),
    district          varchar(100),
    opening_balance   numeric(18,2) NOT NULL DEFAULT 0,  -- positive = customer owes
    pan_number        varchar(50),
    credit_limit      numeric(18,2),    -- max allowed credit
    notes             text,
    is_active         boolean NOT NULL DEFAULT true,
    deleted_at        timestamptz,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    created_by        bigint NOT NULL,
    updated_by        bigint NOT NULL
);
CREATE INDEX ix_customer_business ON customer(business_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_customer_business_name ON customer(business_id, name) WHERE deleted_at IS NULL;
CREATE INDEX ix_customer_business_phone ON customer(business_id, phone_number) WHERE deleted_at IS NULL;
```

### 6.2 supplier

```sql
CREATE TABLE supplier (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id       bigint NOT NULL REFERENCES business(id),
    name              varchar(200) NOT NULL,
    phone_number      varchar(20),
    email             varchar(256),
    address_line      varchar(500),
    city              varchar(100),
    district          varchar(100),
    opening_balance   numeric(18,2) NOT NULL DEFAULT 0,  -- positive = we owe supplier
    pan_number        varchar(50),
    notes             text,
    is_active         boolean NOT NULL DEFAULT true,
    deleted_at        timestamptz,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    created_by        bigint NOT NULL,
    updated_by        bigint NOT NULL
);
CREATE INDEX ix_supplier_business ON supplier(business_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_supplier_business_name ON supplier(business_id, name) WHERE deleted_at IS NULL;
```

---

## 7. Sales Tables

### 7.1 sale

```sql
CREATE TABLE sale (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id       bigint NOT NULL REFERENCES business(id),
    invoice_number    varchar(50) NOT NULL,   -- business-specific invoice sequence
    customer_id       bigint REFERENCES customer(id),
    sale_type         varchar(10) NOT NULL,   -- 'cash', 'credit', 'partial'
    sale_date         date NOT NULL,
    subtotal          numeric(18,2) NOT NULL DEFAULT 0,
    discount_amount   numeric(18,2) NOT NULL DEFAULT 0,
    tax_amount        numeric(18,2) NOT NULL DEFAULT 0,
    total_amount       numeric(18,2) NOT NULL DEFAULT 0,
    paid_amount       numeric(18,2) NOT NULL DEFAULT 0,
    due_amount        numeric(18,2) NOT NULL DEFAULT 0,  -- total - paid
    payment_status    varchar(15) NOT NULL DEFAULT 'unpaid',  -- 'paid', 'partial', 'unpaid'
    notes             text,
    attachment_ids    bigint[],
    deleted_at        timestamptz,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    created_by        bigint NOT NULL,
    updated_by        bigint NOT NULL,
    CONSTRAINT uq_sale_business_invoice UNIQUE (business_id, invoice_number)
);
CREATE INDEX ix_sale_business_date ON sale(business_id, sale_date) WHERE deleted_at IS NULL;
CREATE INDEX ix_sale_customer ON sale(business_id, customer_id) WHERE deleted_at IS NULL;
CREATE INDEX ix_sale_payment_status ON sale(business_id, payment_status) WHERE deleted_at IS NULL;
```

### 7.2 sale_item

```sql
CREATE TABLE sale_item (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sale_id         bigint NOT NULL REFERENCES sale(id) ON DELETE CASCADE,
    business_id     bigint NOT NULL REFERENCES business(id),
    product_id      bigint REFERENCES product(id),
    description     varchar(500),   -- free-text line item (can exist without product)
    unit_id         bigint REFERENCES unit(id),
    quantity        numeric(18,3) NOT NULL,
    unit_price      numeric(18,2) NOT NULL,
    discount_amount numeric(18,2) NOT NULL DEFAULT 0,
    tax_amount      numeric(18,2) NOT NULL DEFAULT 0,
    line_total      numeric(18,2) NOT NULL,  -- qty * price - discount + tax
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL
);
CREATE INDEX ix_sale_item_sale ON sale_item(sale_id);
CREATE INDEX ix_sale_item_product ON sale_item(business_id, product_id);
```

---

## 8. Purchase Tables

### 8.1 purchase

```sql
CREATE TABLE purchase (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id       bigint NOT NULL REFERENCES business(id),
    invoice_number    varchar(50),    -- supplier's invoice/ref number
    supplier_id       bigint REFERENCES supplier(id),
    purchase_type     varchar(10) NOT NULL,  -- 'cash', 'credit', 'partial'
    purchase_date     date NOT NULL,
    subtotal          numeric(18,2) NOT NULL DEFAULT 0,
    discount_amount   numeric(18,2) NOT NULL DEFAULT 0,
    tax_amount        numeric(18,2) NOT NULL DEFAULT 0,
    total_amount       numeric(18,2) NOT NULL DEFAULT 0,
    paid_amount       numeric(18,2) NOT NULL DEFAULT 0,
    due_amount        numeric(18,2) NOT NULL DEFAULT 0,
    payment_status    varchar(15) NOT NULL DEFAULT 'unpaid',
    notes             text,
    deleted_at        timestamptz,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    created_by        bigint NOT NULL,
    updated_by        bigint NOT NULL
);
CREATE INDEX ix_purchase_business_date ON purchase(business_id, purchase_date) WHERE deleted_at IS NULL;
CREATE INDEX ix_purchase_supplier ON purchase(business_id, supplier_id) WHERE deleted_at IS NULL;
```

### 8.2 purchase_item

```sql
CREATE TABLE purchase_item (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_id     bigint NOT NULL REFERENCES purchase(id) ON DELETE CASCADE,
    business_id     bigint NOT NULL REFERENCES business(id),
    product_id      bigint REFERENCES product(id),
    description     varchar(500),
    unit_id         bigint REFERENCES unit(id),
    quantity        numeric(18,3) NOT NULL,
    unit_price      numeric(18,2) NOT NULL,
    discount_amount numeric(18,2) NOT NULL DEFAULT 0,
    tax_amount      numeric(18,2) NOT NULL DEFAULT 0,
    line_total      numeric(18,2) NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL
);
CREATE INDEX ix_purchase_item_purchase ON purchase_item(purchase_id);
```

---

## 9. Expense & Income Tables

### 9.1 expense

```sql
CREATE TABLE expense (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id     bigint NOT NULL REFERENCES business(id),
    category        varchar(100),      -- 'rent', 'salary', 'utilities', 'transport'
    title           varchar(200) NOT NULL,
    description     text,
    amount          numeric(18,2) NOT NULL,
    expense_date    date NOT NULL,
    payment_method  varchar(30),       -- 'cash', 'bank', 'esewa', etc.
    deleted_at      timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL,
    updated_by      bigint NOT NULL
);
CREATE INDEX ix_expense_business_date ON expense(business_id, expense_date) WHERE deleted_at IS NULL;
```

### 9.2 income

```sql
CREATE TABLE income (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id     bigint NOT NULL REFERENCES business(id),
    category        varchar(100),
    title           varchar(200) NOT NULL,
    description     text,
    amount          numeric(18,2) NOT NULL,
    income_date     date NOT NULL,
    payment_method  varchar(30),
    deleted_at      timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL,
    updated_by      bigint NOT NULL
);
CREATE INDEX ix_income_business_date ON income(business_id, income_date) WHERE deleted_at IS NULL;
```

---

## 10. Ledger (Khata) Tables

### 10.1 ledger_account

Represents a running account for a customer or supplier.

```sql
CREATE TABLE ledger_account (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id      bigint NOT NULL REFERENCES business(id),
    party_type       varchar(10) NOT NULL,   -- 'customer' | 'supplier'
    party_id         bigint NOT NULL,         -- customer.id or supplier.id
    opening_balance  numeric(18,2) NOT NULL DEFAULT 0,
    current_balance  numeric(18,2) NOT NULL DEFAULT 0,  -- cached, derived from transactions
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    created_by        bigint NOT NULL,
    updated_by        bigint NOT NULL,
    CONSTRAINT uq_ledger_account_business_party UNIQUE (business_id, party_type, party_id)
);
CREATE INDEX ix_ledger_account_business ON ledger_account(business_id, party_type);
```

### 10.2 ledger_transaction

Immutable record of every debit/credit movement on a ledger account.

```sql
CREATE TABLE ledger_transaction (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id      bigint NOT NULL REFERENCES business(id),
    ledger_account_id bigint NOT NULL REFERENCES ledger_account(id),
    transaction_type varchar(15) NOT NULL,   -- 'debit', 'credit'
    -- For customer: debit = they owe more (sale), credit = they paid
    -- For supplier: debit = we paid, credit = we owe more (purchase)
    amount           numeric(18,2) NOT NULL,
    balance_after    numeric(18,2) NOT NULL,  -- running balance after this txn
    transaction_date date NOT NULL,
    reference_type   varchar(20),   -- 'sale', 'purchase', 'payment', 'adjustment', 'opening'
    reference_id     bigint,         -- FK to the source record
    description      varchar(500),
    created_at       timestamptz NOT NULL DEFAULT now(),
    created_by       bigint NOT NULL
    -- Immutable: no updated_at, no deleted_at
);
CREATE INDEX ix_ledger_txn_account_date ON ledger_transaction(ledger_account_id, transaction_date);
CREATE INDEX ix_ledger_txn_business ON ledger_transaction(business_id, transaction_date);
CREATE INDEX ix_ledger_txn_reference ON ledger_transaction(reference_type, reference_id);
```

---

## 11. Payment Tables

### 11.1 payment_method

```sql
CREATE TABLE payment_method (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id  bigint NOT NULL REFERENCES business(id),
    name         varchar(50) NOT NULL,   -- 'Cash', 'eSewa', 'Khalti', 'Bank Transfer'
    provider     varchar(50),            -- null for cash; 'esewa', 'khalti', 'fonepay'
    is_active    boolean NOT NULL DEFAULT true,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    created_by   bigint NOT NULL,
    updated_by   bigint NOT NULL,
    CONSTRAINT uq_payment_method_business_name UNIQUE (business_id, name)
);
```

### 11.2 payment

```sql
CREATE TABLE payment (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id     bigint NOT NULL REFERENCES business(id),
    party_type      varchar(10) NOT NULL,  -- 'customer' | 'supplier'
    party_id        bigint NOT NULL,        -- customer.id or supplier.id
    payment_date    date NOT NULL,
    amount          numeric(18,2) NOT NULL,
    payment_method_id bigint REFERENCES payment_method(id),
    reference_type  varchar(20),   -- 'sale', 'purchase', 'general'
    reference_id    bigint,         -- FK to sale.id or purchase.id
    notes           text,
    deleted_at      timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL,
    updated_by      bigint NOT NULL
);
CREATE INDEX ix_payment_business_date ON payment(business_id, payment_date) WHERE deleted_at IS NULL;
CREATE INDEX ix_payment_party ON payment(business_id, party_type, party_id) WHERE deleted_at IS NULL;
```

---

## 12. Invoice & Quotation Tables

### 12.1 invoice

```sql
CREATE TABLE invoice (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id     bigint NOT NULL REFERENCES business(id),
    invoice_number  varchar(50) NOT NULL,
    customer_id     bigint REFERENCES customer(id),
    invoice_date    date NOT NULL,
    due_date        date,
    subtotal        numeric(18,2) NOT NULL DEFAULT 0,
    discount_amount numeric(18,2) NOT NULL DEFAULT 0,
    tax_amount      numeric(18,2) NOT NULL DEFAULT 0,
    total_amount    numeric(18,2) NOT NULL DEFAULT 0,
    paid_amount     numeric(18,2) NOT NULL DEFAULT 0,
    notes           text,
    terms_conditions text,
    pdf_url         varchar(512),
    status          varchar(15) NOT NULL DEFAULT 'draft',  -- 'draft', 'sent', 'paid', 'partial', 'overdue'
    deleted_at      timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL,
    updated_by      bigint NOT NULL,
    CONSTRAINT uq_invoice_business_number UNIQUE (business_id, invoice_number)
);
CREATE INDEX ix_invoice_business_date ON invoice(business_id, invoice_date) WHERE deleted_at IS NULL;
```

### 12.2 invoice_item

```sql
CREATE TABLE invoice_item (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id      bigint NOT NULL REFERENCES invoice(id) ON DELETE CASCADE,
    business_id     bigint NOT NULL REFERENCES business(id),
    product_id      bigint REFERENCES product(id),
    description     varchar(500),
    quantity        numeric(18,3) NOT NULL,
    unit_price      numeric(18,2) NOT NULL,
    discount_amount numeric(18,2) NOT NULL DEFAULT 0,
    tax_amount      numeric(18,2) NOT NULL DEFAULT 0,
    line_total      numeric(18,2) NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL
);
```

### 12.3 quotation

```sql
CREATE TABLE quotation (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id       bigint NOT NULL REFERENCES business(id),
    quotation_number  varchar(50) NOT NULL,
    customer_id       bigint REFERENCES customer(id),
    quotation_date    date NOT NULL,
    valid_until        date,
    subtotal          numeric(18,2) NOT NULL DEFAULT 0,
    discount_amount   numeric(18,2) NOT NULL DEFAULT 0,
    tax_amount        numeric(18,2) NOT NULL DEFAULT 0,
    total_amount      numeric(18,2) NOT NULL DEFAULT 0,
    notes             text,
    terms_conditions   text,
    status            varchar(15) NOT NULL DEFAULT 'draft',  -- 'draft', 'sent', 'accepted', 'rejected', 'expired'
    converted_sale_id bigint REFERENCES sale(id),  -- if converted to sale
    deleted_at        timestamptz,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    created_by        bigint NOT NULL,
    updated_by        bigint NOT NULL,
    CONSTRAINT uq_quotation_business_number UNIQUE (business_id, quotation_number)
);
```

### 12.4 quotation_item

```sql
CREATE TABLE quotation_item (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    quotation_id    bigint NOT NULL REFERENCES quotation(id) ON DELETE CASCADE,
    business_id     bigint NOT NULL REFERENCES business(id),
    product_id      bigint REFERENCES product(id),
    description     varchar(500),
    quantity        numeric(18,3) NOT NULL,
    unit_price      numeric(18,2) NOT NULL,
    discount_amount numeric(18,2) NOT NULL DEFAULT 0,
    tax_amount      numeric(18,2) NOT NULL DEFAULT 0,
    line_total      numeric(18,2) NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL
);
```

---

## 13. Notification & Reminder Tables

Added in Phase 10. Timestamps are stored **UTC** (`timestamptz`) and converted
to Nepal local (UTC+05:45) at the DTO boundary.

### 13.1 notification

Per-user in-app feed. A due reminder writes one of these unconditionally; the
push itself is best-effort.

```sql
CREATE TABLE notification (
    "Id"              bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    "BusinessId"      bigint NOT NULL REFERENCES business ("Id") ON DELETE CASCADE,
    "UserId"          bigint NOT NULL,
    "Category"        varchar(20) NOT NULL,  -- 'Reminder'|'LowStock'|'PaymentDue'|'Backup'|'System'
    "Title"           varchar(200) NOT NULL,
    "Body"            varchar(1000),
    "ReferenceType"   varchar(30),           -- e.g. 'reminder' | 'product' | 'sale'
    "ReferenceId"     bigint,
    "ReadAt"          timestamptz,           -- NULL = unread
    "DeletedAt"       timestamptz,           -- soft delete
    "CreatedAt"       timestamptz NOT NULL,
    "UpdatedAt"       timestamptz NOT NULL,
    "CreatedBy"       bigint NOT NULL,
    "UpdatedBy"       bigint NOT NULL
);
CREATE INDEX "IX_notification_BusinessId_UserId_ReadAt"
    ON notification ("BusinessId", "UserId", "ReadAt");
CREATE INDEX "IX_notification_DeletedAt" ON notification ("DeletedAt");
```

### 13.2 device_registration

One row per FCM token. The token is globally unique — the same token sent again
refreshes its business/user/platform instead of duplicating.

```sql
CREATE TABLE device_registration (
    "Id"          bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    "BusinessId"  bigint NOT NULL REFERENCES business ("Id") ON DELETE CASCADE,
    "UserId"      bigint NOT NULL,
    "Token"       varchar(512) NOT NULL,
    "Platform"    varchar(20) NOT NULL,   -- 'Android'|'Ios'|'Web'
    "DeviceName"  varchar(100),
    "IsActive"    boolean NOT NULL DEFAULT true,
    "LastSeenAt"  timestamptz,
    "CreatedAt"   timestamptz NOT NULL,
    "UpdatedAt"   timestamptz NOT NULL,
    "CreatedBy"   bigint NOT NULL,
    "UpdatedBy"   bigint NOT NULL
);
CREATE UNIQUE INDEX "IX_device_registration_Token" ON device_registration ("Token");
```

`IsActive` flips to `false` when FCM answers `UNREGISTERED` or 404, so a stale
token stops being retried.

### 13.3 notification_settings

Per user per business. One row per user; all categories default to enabled.

```sql
CREATE TABLE notification_settings (
    "Id"                 bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    "BusinessId"         bigint NOT NULL REFERENCES business ("Id") ON DELETE CASCADE,
    "UserId"             bigint NOT NULL,
    "PushEnabled"        boolean NOT NULL DEFAULT true,
    "ReminderEnabled"    boolean NOT NULL DEFAULT true,
    "LowStockEnabled"    boolean NOT NULL DEFAULT true,
    "PaymentDueEnabled"  boolean NOT NULL DEFAULT true,
    "BackupEnabled"      boolean NOT NULL DEFAULT true,
    "SystemEnabled"      boolean NOT NULL DEFAULT true,
    "CreatedAt"          timestamptz NOT NULL,
    "UpdatedAt"          timestamptz NOT NULL,
    "CreatedBy"          bigint NOT NULL,
    "UpdatedBy"          bigint NOT NULL
);
CREATE UNIQUE INDEX "IX_notification_settings_BusinessId_UserId"
    ON notification_settings ("BusinessId", "UserId");
```

### 13.4 reminder

A dated to-do. `DueAt` is UTC; the API accepts and returns Nepal local time.

```sql
CREATE TABLE reminder (
    "Id"                 bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    "BusinessId"         bigint NOT NULL REFERENCES business ("Id") ON DELETE CASCADE,
    "Title"              varchar(200) NOT NULL,
    "Notes"              varchar(1000),
    "DueAt"              timestamptz NOT NULL,
    "Status"             varchar(20) NOT NULL,   -- 'Pending'|'Done'|'Dismissed'
    "Repeat"             varchar(20) NOT NULL,   -- 'None'|'Daily'|'Weekly'|'Monthly'|'Yearly'
    "RelatedEntityType"  varchar(30),
    "RelatedEntityId"    bigint,
    "UserId"             bigint,                 -- NULL = business owner
    "CompletedAt"        timestamptz,
    "DeletedAt"          timestamptz,
    "CreatedAt"          timestamptz NOT NULL,
    "UpdatedAt"          timestamptz NOT NULL,
    "CreatedBy"          bigint NOT NULL,
    "UpdatedBy"          bigint NOT NULL
);
CREATE INDEX "IX_reminder_BusinessId_Status_DueAt"
    ON reminder ("BusinessId", "Status", "DueAt");
CREATE INDEX "IX_reminder_DeletedAt" ON reminder ("DeletedAt");
```

### 13.5 backup_restore_entry

The restore id ledger: one row per row written by a backup restore. It is the
restore's idempotency guard, in the same spirit as `sync_operation` for sync
pushes.

Why it is needed: primary keys are global, so a payload id already owned by
another business cannot be inserted verbatim — the restore writes the row under
a free id instead. A second restore of the same file would then not recognise
those rows by payload id and would insert them again. The ledger remembers
`SourceId → TargetId` per backup file, so a repeat restore is a no-op even
after re-homing or after the user renames a row.

```sql
CREATE TABLE backup_restore_entry (
    "Id"          bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    "BusinessId"  bigint NOT NULL REFERENCES business ("Id") ON DELETE CASCADE,
    "BackupKey"   varchar(100) NOT NULL,  -- "<sourceBusinessId>:<exportedAt ticks>"
    "EntityType"  varchar(40) NOT NULL,   -- 'sale', 'product', 'payment', ...
    "SourceId"    bigint NOT NULL,        -- the id the row had in the source business
    "TargetId"    bigint NOT NULL,        -- the id it was written under here
    "CreatedAt"   timestamptz NOT NULL,
    "UpdatedAt"   timestamptz NOT NULL,
    "CreatedBy"   bigint NOT NULL,
    "UpdatedBy"   bigint NOT NULL
);
CREATE INDEX "IX_backup_restore_entry_BusinessId_BackupKey"
    ON backup_restore_entry ("BusinessId", "BackupKey");
CREATE UNIQUE INDEX "IX_backup_restore_entry_BusinessId_BackupKey_EntityType_SourceId"
    ON backup_restore_entry ("BusinessId", "BackupKey", "EntityType", "SourceId");
```

---

## 14. Supporting Tables

### 14.1 attachment

```sql
CREATE TABLE attachment (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id     bigint NOT NULL REFERENCES business(id),
    file_name       varchar(256) NOT NULL,
    file_url        varchar(512) NOT NULL,   -- S3-compatible URL
    file_type       varchar(50),             -- MIME type
    file_size       bigint,                  -- bytes
    reference_type  varchar(30),   -- 'sale', 'purchase', 'expense', 'product'
    reference_id    bigint,
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL
);
CREATE INDEX ix_attachment_reference ON attachment(business_id, reference_type, reference_id);
```

### 14.2 sync_record

Server-side record of sync operations received from mobile clients.
Used for debugging and conflict resolution.

```sql
CREATE TABLE sync_record (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id     bigint NOT NULL REFERENCES business(id),
    user_id         bigint NOT NULL REFERENCES app_user(id),
    device_id       varchar(100) NOT NULL,
    entity_type     varchar(50) NOT NULL,   -- 'sale', 'purchase', 'product', etc.
    local_id        varchar(64) NOT NULL,    -- client UUID
    server_id       bigint,                  -- assigned server ID (null if failed)
    operation       varchar(10) NOT NULL,    -- 'create', 'update', 'delete'
    payload_hash    varchar(64),            -- SHA-256 of payload for dedup
    status          varchar(15) NOT NULL,    -- 'success', 'conflict', 'failed'
    error_message   text,
    received_at     timestamptz NOT NULL DEFAULT now(),
    processed_at    timestamptz,
    CONSTRAINT uq_sync_record_local UNIQUE (business_id, entity_type, local_id)
);
CREATE INDEX ix_sync_record_business ON sync_record(business_id, received_at);
CREATE INDEX ix_sync_record_status ON sync_record(status, received_at);
```

### 14.3 audit_log

```sql
CREATE TABLE audit_log (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id     bigint NOT NULL REFERENCES business(id),
    user_id         bigint REFERENCES app_user(id),
    entity_type     varchar(50) NOT NULL,
    entity_id       bigint,
    action          varchar(10) NOT NULL,    -- 'create', 'update', 'delete'
    old_values      jsonb,                   -- JSON snapshot before change
    new_values      jsonb,                   -- JSON snapshot after change
    ip_address      varchar(45),
    user_agent      varchar(500),
    created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_audit_log_business ON audit_log(business_id, created_at);
CREATE INDEX ix_audit_log_entity ON audit_log(entity_type, entity_id);
```

---

## 15. Index Strategy Summary

| Index Purpose | Pattern |
|---------------|---------|
| Tenant scoping | `ix_{table}_business` on every business table |
| Date filtering | `ix_{table}_business_date` (composite: business + date) |
| Soft delete | `WHERE deleted_at IS NULL` partial index |
| Search | `ix_{table}_business_name`, `ix_{table}_business_phone` |
| Unique business constraints | `uq_{table}_business_{col}` |
| Foreign key | Auto-index on FK columns by EF Core |

---

## 16. EF Core Configuration

### 16.1 Base Entity Configuration

```csharp
// All business entities implement:
public interface IBusinessEntity
{
    long BusinessId { get; set; }
    Business Business { get; set; }
}

public abstract class AuditableEntity
{
    public long Id { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public long CreatedBy { get; set; }
    public long UpdatedBy { get; set; }
}

public abstract class SoftDeletableEntity : AuditableEntity
{
    public DateTime? DeletedAt { get; set; }
}
```

### 16.2 Global Query Filters

```csharp
// In KhataDbContext.OnModelCreating:
modelBuilder.EntitiesOfType<IBusinessEntity>()
    .HasQueryFilter(e => EF.Property<long>(e, "BusinessId") == _currentUserService.BusinessId);

modelBuilder.EntitiesOfType<ISoftDeletable>()
    .HasQueryFilter(e => EF.Property<DateTime?>(e, "DeletedAt") == null);
```

### 16.3 Decimal Precision

```csharp
modelBuilder.Entity<Sale>()
    .Property(s => s.TotalAmount)
    .HasPrecision(18, 2);
```

All `decimal` properties are configured with `HasPrecision(18, 2)` to ensure
PostgreSQL `numeric(18,2)` mapping.

---

## 17. Seed Data

System roles and permissions are seeded on first run:

| Role | Permissions |
|------|------------|
| Owner | All permissions |
| Admin | All except `settings.manage` (business deletion) |
| Manager | sales.*, purchase.*, inventory.*, customers.*, suppliers.*, reports.view |
| Accountant | reports.view, payments.*, khata.view |
| SalesStaff | sales.view, sales.create, sales.edit, customers.view, customers.create |
| InventoryStaff | inventory.view, inventory.create, inventory.adjust, products.view |
| Viewer | *.view (read-only across all) |

Permission codes follow `{module}.{action}` pattern:
`sales.view`, `sales.create`, `sales.edit`, `sales.delete`, `purchase.view`,
`purchase.create`, `purchase.edit`, `inventory.view`, `inventory.create`,
`inventory.adjust`, `customers.view`, `customers.create`, `customers.edit`,
`reports.view`, `settings.manage`, etc.
