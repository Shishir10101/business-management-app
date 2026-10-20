# Security

> Security architecture for Nepal Digital Khata.
> Never trust client-side validation alone. The API is the security boundary.

---

## 1. Authentication

### 1.1 Password Security

- Passwords hashed using ASP.NET Core Identity v4 (PBKDF2 with HMAC-SHA256)
- Minimum: 8 characters, require letter + digit
- Password breach check: compare against known-breach password list
- Password history: prevent reusing last 3 passwords
- Account lockout: 5 failed attempts → 15-minute lockout

### 1.2 JWT Tokens

| Token Type | Lifetime | Storage |
|------------|----------|---------|
| Access token | 60 minutes | Flutter: `flutter_secure_storage` (encrypted KeyStore/Keychain) |
| Refresh token | 30 days (rotating) | Flutter: `flutter_secure_storage`; Server: hashed in DB |

### 1.3 JWT Claims

```json
{
  "sub": "1",                    // user ID
  "bid": "1",                    // active business ID
  "name": "Ram Sharma",
  "email": "ram@example.com",
  "roles": ["Owner"],
  "perms": ["sales.create", "inventory.adjust", ...],
  "jti": "unique-token-id",
  "iat": 1696460641,
  "exp": 1696464241
}
```

### 1.4 Refresh Token Rotation

- Each refresh produces a new access token AND a new refresh token
- Old refresh token is revoked (added to server-side revoked list)
- If a revoked refresh token is used → potential token theft → revoke entire token family → force re-login

### 1.5 Token Storage on Mobile

```dart
// flutter_secure_storage uses platform-encrypted storage:
// Android: AndroidKeyStore (hardware-backed on supported devices)
// iOS: Keychain (Secure Enclave on supported devices)
final storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: token);
await storage.write(key: 'refresh_token', value: refreshToken);
```

- Tokens are never stored in SharedPreferences or plain files
- Tokens are cleared on logout

---

## 2. Authorization (RBAC)

### 2.1 Permission Enforcement

Permissions are enforced at **three layers**:

| Layer | Mechanism |
|-------|-----------|
| Flutter UI | Hide/disable buttons based on `perms` claim in JWT |
| API Controller | `[HasPermission("sales.create")]` attribute |
| Application Handler | Double-check permission in handler before executing |

**Hiding UI buttons is UX, not security.** The API always validates.

### 2.2 Permission Attribute

```csharp
[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class HasPermissionAttribute : AuthorizeAttribute
{
    public HasPermissionAttribute(string permission)
    {
        Policy = $"Permission:{permission}";
    }
}

// In Program.cs:
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("Permission:sales.create",
        policy => policy.RequireClaim("perms", "sales.create"));
});

// Usage:
[HttpPost]
[HasPermission("sales.create")]
public async Task<ActionResult<SaleDto>> Create(CreateSaleCommand command)
```

### 2.3 Role Definitions

| Role | Permissions (summary) |
|------|----------------------|
| Owner | All permissions including `settings.manage` |
| Admin | All except business deletion and subscription management |
| Manager | sales.*, purchase.*, inventory.*, customers.*, suppliers.*, reports.view |
| Accountant | reports.view, payments.*, ledger.view, expenses.view, income.view |
| SalesStaff | sales.view, sales.create, sales.edit, customers.view, customers.create |
| InventoryStaff | inventory.view, inventory.create, inventory.adjust, products.view |
| Viewer | All `.view` permissions (read-only) |

### 2.4 Tenant Isolation

Every business entity is filtered by `BusinessId` from the JWT `bid` claim.

```csharp
// EF Core global query filter:
modelBuilder.Entity<Sale>()
    .HasQueryFilter(e => e.BusinessId == _currentUserService.BusinessId);
```

Even if a user has `sales.view` permission, they can only see sales for
their **active** business. Switching businesses updates the JWT `bid` claim.

---

## 3. Input Validation

### 3.1 FluentValidation (Backend)

Every command/query has a validator:

```csharp
public class CreateSaleValidator : AbstractValidator<CreateSaleCommand>
{
    public CreateSaleValidator()
    {
        RuleFor(x => x.CustomerId).GreaterThan(0).When(x => x.CustomerId.HasValue);
        RuleFor(x => x.SaleDate).NotEmpty().LessThanOrEqualTo(DateTime.UtcNow);
        RuleFor(x => x.Items).NotEmpty().WithMessage("At least one item is required");
        RuleForEach(x => x.Items).SetValidator(new SaleItemValidator());
        RuleFor(x => x.DiscountAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.Items.Sum(i => i.Quantity)).GreaterThan(0);
    }
}
```

### 3.2 SQL Injection Prevention

EF Core uses parameterized queries exclusively. No raw SQL string concatenation.
Any raw SQL (for complex reporting) uses `FromSqlInterpolated` with parameters.

### 3.3 XSS Prevention

The API returns JSON, not HTML. Admin web (future) uses a framework with
automatic output encoding. No `innerHTML` or `dangerouslySetHTML` without sanitization.

### 3.4 File Upload Security

- Max file size: 5MB for images, 10MB for documents
- Allowed MIME types whitelist: `image/jpeg`, `image/png`, `image/webp`, `application/pdf`
- File content verified by magic bytes (not just extension)
- Files stored in S3-compatible object storage, not on app server
- File names sanitized (UUID generated, original name stored as metadata)
- No executable uploads

---

## 4. API Security

### 4.1 Rate Limiting

```csharp
// ASP.NET Core 8+ built-in rate limiting
builder.Services.AddRateLimiter(options =>
{
    options.AddPolicy("auth", ctx => ctx.GetEndpoint()
        .Metadata.GetMetadata<RequireAuthRateLimit>() != null
        ? RateLimitPartition.GetFixedWindowLimiter(ctx.Connection.RemoteIpAddress,
            factory: _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1) })
        : null);
});
```

### 4.2 CORS

- Production: only allow `https://admin.khata.app` (future admin web)
- Mobile: no CORS needed (not a browser client)

### 4.3 HTTPS Enforcement

- API requires HTTPS in production (HSTS enabled)
- HTTP requests are redirected to HTTPS
- No mixed content

### 4.4 Request Size Limits

- Max request body: 10MB (for file uploads)
- Max JSON payload: 1MB for regular API calls

---

## 5. Audit Logging

### 5.1 What Gets Logged

All create/update/delete operations on financial entities:
- Sale, Purchase, Payment, Expense, Income
- LedgerTransaction
- StockMovement (already immutable)
- Product price changes
- Customer/Supplier balance adjustments

### 5.2 Audit Log Entry

```csharp
// AuditLog entity (see database.md §14.3)
// Captured automatically via EF Core SaveChanges interceptor:
public class AuditInterceptor : SaveChangesInterceptor
{
    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData, InterceptionResult<int> result)
    {
        var entries = eventData.Context!.ChangeTracker.Entries()
            .Where(e => e.State is EntityState.Modified or EntityState.Deleted or EntityState.Added)
            .Where(e => e.Entity is IAuditable);

        foreach (var entry in entries)
        {
            // Create AuditLog entry with old/new values as JSONB
        }
        return base.SavingChangesAsync(eventData, result);
    }
}
```

### 5.3 Audit Log Access

Audit logs are viewable by Owner and Admin roles. They cannot be deleted
or modified. Logs are retained indefinitely (or per legal requirements).

---

## 6. Security Headers

```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0  (deprecated, but set to 0 to avoid UA XSS auditor issues)
Content-Security-Policy: default-src 'self' (for admin web)
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

---

## 7. Mobile Security

### 7.1 Local Data Encryption

- SQLite database is encrypted using `sqlcipher` (via Drift's encryption support)
- Encryption key stored in platform-encrypted storage (KeyStore/Keychain)
- Database is encrypted at rest; decrypted in memory only

### 7.2 Certificate Pinning (Future)

For production, pin the API server's TLS certificate to prevent MITM attacks.
Dio supports certificate pinning via `HttpClient` configuration.

### 7.3 Root/Jailbreak Detection

- Warn the user if the device appears rooted/jailbroken
- On rooted devices, consider refusing to store tokens locally
- This is a warning, not a hard block (many legitimate users root their devices)

### 7.4 Screenshot Prevention (Future)

For screens showing financial data, optionally set `FLAG_SECURE` on Android
to prevent screenshots. Configurable in settings.

---

## 8. Payment Security

### 8.1 Payment Provider Abstraction

```csharp
public interface IPaymentProvider
{
    string Name { get; }
    Task<PaymentResult> InitiatePaymentAsync(PaymentRequest request);
    Task<PaymentResult> VerifyPaymentAsync(string transactionId);
}

// Only implement when real credentials/API docs are available:
// - EsewaPaymentProvider
// - KhaltiPaymentProvider
// - FonepayPaymentProvider
// - CashPaymentProvider (no external API needed)
// - BankPaymentProvider (manual reconciliation)
```

### 8.2 Payment Data Handling

- Never store full payment provider credentials in the database
- Use environment variables / Azure Key Vault / similar for API keys
- Payment verification is always server-side (never trust client-confirmed payment)
- Payment provider webhooks are verified via signature

---

## 9. Vulnerability Management

| Practice | Frequency |
|----------|-----------|
| Dependency audit (`dotnet list --vulnerable`, `npm audit`) | Every CI build |
| SAST (static analysis) | Every PR |
| Penetration testing | Before major release |
| Security review of auth/RBAC code | Every change to auth flows |

---

## 10. Compliance Notes

- This application handles financial data for Nepali businesses
- Follow Nepal's data protection guidelines (if applicable)
- User data is not sold or shared with third parties
- Users can export and delete their data (backup feature + account deletion)
- Audit logs support accountability and dispute resolution
