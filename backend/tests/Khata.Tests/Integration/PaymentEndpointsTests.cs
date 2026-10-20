using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Domain.Enums;
using Khata.Infrastructure.Data;
using Khata.Tests.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// Payments: the payment → ledger → balance chain, applying a payment to a
/// sale/purchase (due + status), overpayment becoming a credit balance, the
/// receivable/payable summary, and payment immutability.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class PaymentEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public PaymentEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task CustomerPayment_UpdatesSaleDue_AndKhataBalance()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 10000, 50);
        var customer = await CreateCustomerAsync(client);
        var sale = await CreateCreditSaleAsync(client, customer.Id, product.Id, quantity: 1, unitPrice: 10000);

        Assert.Equal(10000, sale.DueAmount);

        var payment = await CreatePaymentAsync(client, new
        {
            partyType = "Customer",
            partyId = customer.Id,
            amount = 6000L,
            saleId = sale.Id,
        });

        Assert.Equal(6000, payment.Amount);
        Assert.Equal(6000, payment.AppliedAmount);
        Assert.Equal(0, payment.UnappliedAmount);
        Assert.Equal(PaymentDirection.In, payment.Direction);

        // Sale: 6000 paid, 4000 due, now Partial.
        var updated = await client.GetFromJsonAsync<SaleDto>($"/api/sales/{sale.Id}", JsonOptions);
        Assert.Equal(6000, updated!.PaidAmount);
        Assert.Equal(4000, updated.DueAmount);
        Assert.Equal(PaymentStatus.Partial, updated.PaymentStatus);

        // Khata: 10000 Debit (sale) then 6000 Credit (payment) → 4000 receivable.
        var ledger = await GetCustomerLedgerAsync(client, customer.Id);
        Assert.Equal(4000, ledger.Summary.ClosingBalance);
        Assert.Equal(2, ledger.Data.Count);
        Assert.Equal("payment", ledger.Data[0].ReferenceType);
        Assert.Equal(LedgerEntryType.Credit, ledger.Data[0].TransactionType);
        Assert.Equal(6000, ledger.Data[0].Amount);
    }

    [Fact]
    public async Task CustomerPayment_FullSettlement_MarksSalePaid_AndClearsKhata()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 8000, 50);
        var customer = await CreateCustomerAsync(client);
        var sale = await CreateCreditSaleAsync(client, customer.Id, product.Id, 1, 8000);

        await CreatePaymentAsync(client, new
        {
            partyType = "Customer",
            partyId = customer.Id,
            amount = 8000L,
            saleId = sale.Id,
        });

        var updated = await client.GetFromJsonAsync<SaleDto>($"/api/sales/{sale.Id}", JsonOptions);
        Assert.Equal(PaymentStatus.Paid, updated!.PaymentStatus);
        Assert.Equal(0, updated.DueAmount);

        var ledger = await GetCustomerLedgerAsync(client, customer.Id);
        Assert.Equal(0, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task Overpayment_LeavesCreditBalance_AndFullySettlesTheSale()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 10000, 50);
        var customer = await CreateCustomerAsync(client);
        var sale = await CreateCreditSaleAsync(client, customer.Id, product.Id, 1, 10000);

        // Pay 15000 against a 10000 sale.
        var payment = await CreatePaymentAsync(client, new
        {
            partyType = "Customer",
            partyId = customer.Id,
            amount = 15000L,
            saleId = sale.Id,
        });

        Assert.Equal(10000, payment.AppliedAmount);
        Assert.Equal(5000, payment.UnappliedAmount);

        var updated = await client.GetFromJsonAsync<SaleDto>($"/api/sales/{sale.Id}", JsonOptions);
        Assert.Equal(10000, updated!.PaidAmount);
        Assert.Equal(0, updated.DueAmount);
        Assert.Equal(PaymentStatus.Paid, updated.PaymentStatus);

        // The 5000 excess is an advance → negative (credit) balance.
        var ledger = await GetCustomerLedgerAsync(client, customer.Id);
        Assert.Equal(-5000, ledger.Summary.ClosingBalance);

        // And it shows up as a customer advance in the summary.
        var summary = await client.GetFromJsonAsync<ReceivablePayableSummaryDto>("/api/payments/summary", JsonOptions);
        Assert.Equal(0, summary!.TotalReceivable);
        Assert.Equal(5000, summary.CustomerAdvances);
    }

    [Fact]
    public async Task SupplierPayment_ReducesPayable_AndPurchaseDue()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 2000, 0, costPrice: 2000);
        var supplier = await CreateSupplierAsync(client);
        var purchase = await CreateCreditPurchaseAsync(client, supplier.Id, product.Id, 10, 2000);

        Assert.Equal(20000, purchase.DueAmount);

        await CreatePaymentAsync(client, new
        {
            partyType = "Supplier",
            partyId = supplier.Id,
            amount = 5000L,
            purchaseId = purchase.Id,
        });

        var updated = await client.GetFromJsonAsync<PurchaseDto>($"/api/purchases/{purchase.Id}", JsonOptions);
        Assert.Equal(5000, updated!.PaidAmount);
        Assert.Equal(15000, updated.DueAmount);
        Assert.Equal(PaymentStatus.Partial, updated.PaymentStatus);

        // Supplier khata: 20000 Credit (purchase) then 5000 Debit (payment) → 15000 payable.
        var ledger = await GetSupplierLedgerAsync(client, supplier.Id);
        Assert.Equal(15000, ledger.Summary.ClosingBalance);
        Assert.Equal(LedgerEntryType.Debit, ledger.Data[0].TransactionType);
    }

    [Fact]
    public async Task PaymentWithoutLink_StillReducesThePartyBalance()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client, openingBalance: 50000);

        var payment = await CreatePaymentAsync(client, new
        {
            partyType = "Customer",
            partyId = customer.Id,
            amount = 20000L,
        });

        Assert.Equal(0, payment.AppliedAmount);
        Assert.Equal(20000, payment.UnappliedAmount);

        var ledger = await GetCustomerLedgerAsync(client, customer.Id);
        Assert.Equal(30000, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task Payment_UsesTheDefaultMethod_WhenNoneSpecified()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);

        var payment = await CreatePaymentAsync(client, new
        {
            partyType = "Customer",
            partyId = customer.Id,
            amount = 1000L,
        });

        Assert.NotNull(payment.PaymentMethodId);
        Assert.Equal("Cash", payment.MethodName);
    }

    [Fact]
    public async Task Summary_ReportsReceivablePayableAndAdvances()
    {
        var client = await CreateOwnerClientAsync();
        var customerA = await CreateCustomerAsync(client, openingBalance: 30000);
        var customerB = await CreateCustomerAsync(client, openingBalance: 10000);
        var supplier = await CreateSupplierAsync(client, openingBalance: 25000);

        var summary = await client.GetFromJsonAsync<ReceivablePayableSummaryDto>("/api/payments/summary", JsonOptions);

        Assert.Equal(40000, summary!.TotalReceivable);
        Assert.Equal(25000, summary.TotalPayable);
        Assert.Equal(2, summary.ReceivableParties);
        Assert.Equal(1, summary.PayableParties);

        // customerB pays 15000 → becomes an advance; receivable drops.
        await CreatePaymentAsync(client, new
        {
            partyType = "Customer",
            partyId = customerB.Id,
            amount = 15000L,
        });

        var after = await client.GetFromJsonAsync<ReceivablePayableSummaryDto>("/api/payments/summary", JsonOptions);
        Assert.Equal(30000, after!.TotalReceivable);
        Assert.Equal(1, after.ReceivableParties);
        Assert.Equal(5000, after.CustomerAdvances);
    }

    [Fact]
    public async Task Payments_AreImmutable_UpdateIsRejected()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);
        var payment = await CreatePaymentAsync(client, new
        {
            partyType = "Customer",
            partyId = customer.Id,
            amount = 1000L,
        });

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<KhataDbContext>();

        // The test scope has no HTTP context (BusinessId 0), so bypass the tenant
        // filter to load the row directly.
        var stored = await db.Payments.IgnoreQueryFilters().FirstAsync(p => p.Id == payment.Id);
        stored.Reference = "rewritten";

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() => db.SaveChangesAsync());
        Assert.Contains("immutable", error.Message);
    }

    [Fact]
    public async Task Payment_WithDirectionMismatch_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);

        var response = await client.PostAsJsonAsync("/api/payments", new
        {
            partyType = "Customer",
            partyId = customer.Id,
            amount = 1000L,
            direction = "Out",
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task Payment_WithZeroAmount_Returns400()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);

        var response = await client.PostAsJsonAsync("/api/payments", new
        {
            partyType = "Customer",
            partyId = customer.Id,
            amount = 0L,
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Payment_WithUnknownParty_Returns404()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/payments", new
        {
            partyType = "Customer",
            partyId = 999999L,
            amount = 1000L,
        });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Payment_LinkedToAnotherPartysSale_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 5000, 20);
        var owner = await CreateCustomerAsync(client);
        var other = await CreateCustomerAsync(client);
        var sale = await CreateCreditSaleAsync(client, owner.Id, product.Id, 1, 5000);

        var response = await client.PostAsJsonAsync("/api/payments", new
        {
            partyType = "Customer",
            partyId = other.Id,
            amount = 5000L,
            saleId = sale.Id,
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task OtherBusiness_CannotSeePayment_Returns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var customerA = await CreateCustomerAsync(ownerA);
        var paymentA = await CreatePaymentAsync(ownerA, new
        {
            partyType = "Customer",
            partyId = customerA.Id,
            amount = 1000L,
        });

        var ownerB = await CreateOwnerClientAsync();

        var get = await ownerB.GetAsync($"/api/payments/{paymentA.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
    }

    [Fact]
    public async Task GetPayments_FiltersByPartyAndDirection()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);
        var supplier = await CreateSupplierAsync(client);

        await CreatePaymentAsync(client, new { partyType = "Customer", partyId = customer.Id, amount = 1000L });
        await CreatePaymentAsync(client, new { partyType = "Supplier", partyId = supplier.Id, amount = 2000L });

        var customerOnly = await GetPaymentsAsync(client, $"partyType=Customer&partyId={customer.Id}");
        Assert.Single(customerOnly);
        Assert.Equal(PartyType.Customer, customerOnly[0].PartyType);

        var outOnly = await GetPaymentsAsync(client, "direction=Out");
        Assert.Single(outOnly);
        Assert.Equal(PartyType.Supplier, outOnly[0].PartyType);
    }

    // --- helpers ---

    private static async Task<PaymentDto> CreatePaymentAsync(HttpClient client, object body)
    {
        var response = await client.PostAsJsonAsync("/api/payments", body);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<PaymentDto>(JsonOptions))!;
    }

    private static async Task<List<PaymentDto>> GetPaymentsAsync(HttpClient client, string? query = null)
    {
        var url = "/api/payments?pageSize=100" + (query is null ? "" : "&" + query);
        var page = await client.GetFromJsonAsync<PagedResult<PaymentDto>>(url, JsonOptions);
        return page!.Data.ToList();
    }

    private static async Task<PartyLedgerDto> GetCustomerLedgerAsync(HttpClient client, long customerId)
        => (await client.GetFromJsonAsync<PartyLedgerDto>(
            $"/api/customers/{customerId}/ledger?pageSize=100", JsonOptions))!;

    private static async Task<PartyLedgerDto> GetSupplierLedgerAsync(HttpClient client, long supplierId)
        => (await client.GetFromJsonAsync<PartyLedgerDto>(
            $"/api/suppliers/{supplierId}/ledger?pageSize=100", JsonOptions))!;

    private static async Task<SaleDto> CreateCreditSaleAsync(
        HttpClient client, long customerId, long productId, decimal quantity, long unitPrice)
    {
        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            customerId,
            saleType = "Credit",
            items = new[] { new { productId, quantity, unitPrice } },
            paidAmount = 0L,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SaleDto>(JsonOptions))!;
    }

    private static async Task<PurchaseDto> CreateCreditPurchaseAsync(
        HttpClient client, long supplierId, long productId, decimal quantity, long unitPrice)
    {
        var response = await client.PostAsJsonAsync("/api/purchases", new
        {
            supplierId,
            purchaseType = "Credit",
            items = new[] { new { productId, quantity, unitPrice } },
            paidAmount = 0L,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<PurchaseDto>(JsonOptions))!;
    }

    private static async Task<ProductDto> CreateProductAsync(
        HttpClient client, long sellingPrice, double openingQuantity, long costPrice = 0)
    {
        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name = $"P {Guid.NewGuid():n}",
            sellingPrice,
            costPrice,
            openingQuantity,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ProductDto>(JsonOptions))!;
    }

    private static async Task<CustomerDto> CreateCustomerAsync(
        HttpClient client, long openingBalance = 0)
    {
        var response = await client.PostAsJsonAsync("/api/customers", new
        {
            name = $"C {Guid.NewGuid():n}",
            openingBalance,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<CustomerDto>(JsonOptions))!;
    }

    private static async Task<SupplierDto> CreateSupplierAsync(
        HttpClient client, long openingBalance = 0)
    {
        var response = await client.PostAsJsonAsync("/api/suppliers", new
        {
            name = $"S {Guid.NewGuid():n}",
            openingBalance,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SupplierDto>(JsonOptions))!;
    }

    /// <summary>Registers a user, creates a business, switches to it (Owner JWT).</summary>
    private async Task<HttpClient> CreateOwnerClientAsync()
    {
        var client = await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory);

        var create = await client.PostAsJsonAsync("/api/businesses", new
        {
            name = $"Shop {Guid.NewGuid():n}",
            currency = "NPR",
        });
        create.EnsureSuccessStatusCode();
        var business = await create.Content.ReadFromJsonAsync<BusinessDto>(JsonOptions);

        var switchResponse = await client.PostAsJsonAsync($"/api/businesses/{business!.Id}/switch", new { });
        switchResponse.EnsureSuccessStatusCode();
        var auth = await switchResponse.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth!.AccessToken);

        return client;
    }
}
