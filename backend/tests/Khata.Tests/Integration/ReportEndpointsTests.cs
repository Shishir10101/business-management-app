using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.DTOs;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// Dashboard and reports: aggregation accuracy, P&amp;L correctness, trend
/// grouping, inclusive date-range boundaries, CSV export and isolation.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class ReportEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public ReportEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    // --- dashboard ---

    [Fact]
    public async Task Dashboard_ReportsTodaysAndThisMonthsFigures()
    {
        var client = await CreateOwnerClientAsync();
        // cost 6000, sell 10000, 13% tax
        var product = await CreateProductAsync(client, costPrice: 6000, sellingPrice: 10000,
            taxRateBps: 1300, openingQuantity: 50);
        var customer = await CreateCustomerAsync(client);

        await CreateSaleAsync(client, customer.Id, product.Id, quantity: 2, unitPrice: 10000);
        await CreateExpenseAsync(client, "Rent", 3000);
        await CreateIncomeAsync(client, "Interest", 1000);

        var dashboard = await client.GetFromJsonAsync<DashboardDto>("/api/reports/dashboard", JsonOptions);

        Assert.NotNull(dashboard);
        // Sale: subtotal 20000, tax 2600, total 22600.
        Assert.Equal(1, dashboard.TodaySales.Count);
        Assert.Equal(20000, dashboard.TodaySales.Subtotal);
        Assert.Equal(2600, dashboard.TodaySales.Tax);
        Assert.Equal(22600, dashboard.TodaySales.Total);

        // Revenue 20000 − COGS (2 × 6000 = 12000) = 8000 gross.
        Assert.Equal(8000, dashboard.TodayGrossProfit);
        // 8000 + 1000 income − 3000 expenses = 6000.
        Assert.Equal(6000, dashboard.TodayNetProfit);
        Assert.Equal(3000, dashboard.TodayExpenses);
        Assert.Equal(1000, dashboard.TodayIncome);

        // Today falls inside the current month, so the month figures match.
        Assert.Equal(dashboard.TodaySales.Total, dashboard.MonthSales.Total);
        Assert.Equal(dashboard.TodayNetProfit, dashboard.MonthNetProfit);

        // A 14-day trend ending today, and one product in stock.
        Assert.Equal(14, dashboard.Trend.Count);
        Assert.Equal(dashboard.AsOf, dashboard.Trend[^1].Date);
        Assert.Equal(1, dashboard.ProductCount);
        Assert.Equal(1, dashboard.CustomerCount);
    }

    [Fact]
    public async Task Dashboard_ComputesStockValueBalancesAndTopLists()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, costPrice: 5000, sellingPrice: 8000,
            taxRateBps: 0, openingQuantity: 10);
        var customer = await CreateCustomerAsync(client);

        // Credit sale of 4 → stock 6, customer owes 32000.
        await CreateSaleAsync(client, customer.Id, product.Id, quantity: 4, unitPrice: 8000, saleType: "Credit");

        var dashboard = await client.GetFromJsonAsync<DashboardDto>("/api/reports/dashboard", JsonOptions);

        Assert.NotNull(dashboard);
        Assert.Equal(6 * 5000, dashboard.StockCostValue);
        Assert.Equal(6 * 8000, dashboard.StockRetailValue);
        Assert.Equal(32000, dashboard.TotalReceivable);
        Assert.Equal(0, dashboard.TotalPayable);

        var top = Assert.Single(dashboard.TopProducts);
        Assert.Equal(product.Id, top.Id);
        Assert.Equal(32000, top.Amount);
        Assert.Equal(4, top.Quantity);

        var topCustomer = Assert.Single(dashboard.TopCustomers);
        Assert.Equal(customer.Id, topCustomer.Id);
    }

    // --- profit & loss ---

    [Fact]
    public async Task ProfitLoss_ComputesRevenueCogsAndNetProfit()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 6000, 10000, 1300, 50);
        var customer = await CreateCustomerAsync(client);

        await CreateSaleAsync(client, customer.Id, product.Id, 2, 10000);
        await CreateExpenseAsync(client, "Rent", 3000);
        await CreateExpenseAsync(client, "Salary", 2000);
        await CreateIncomeAsync(client, "Interest", 1000);

        var pl = await client.GetFromJsonAsync<ProfitLossDto>(
            "/api/reports/profit-loss?dateFrom=2026-01-01&dateTo=2026-12-31", JsonOptions);

        Assert.NotNull(pl);
        Assert.Equal(20000, pl.Revenue);        // net of discount, excl. tax
        Assert.Equal(12000, pl.CostOfGoods);    // 2 × 6000
        Assert.Equal(8000, pl.GrossProfit);
        Assert.Equal(1000, pl.OtherIncome);
        Assert.Equal(5000, pl.Expenses);
        Assert.Equal(4000, pl.NetProfit);       // 8000 + 1000 − 5000
        Assert.Equal(2600, pl.SalesTaxCollected);

        Assert.Equal(2, pl.ExpensesByCategory.Count);
        Assert.Equal("Rent", pl.ExpensesByCategory[0].Category);
        Assert.Equal(3000, pl.ExpensesByCategory[0].Amount);
        Assert.Equal(2000, pl.ExpensesByCategory[1].Amount);
    }

    // --- sales report + trends ---

    [Fact]
    public async Task SalesReport_TotalsAndDailySeries()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 4000, 5000, 0, 100);
        var customer = await CreateCustomerAsync(client);

        await CreateSaleAsync(client, customer.Id, product.Id, 1, 5000, saleDate: "2026-10-01");
        await CreateSaleAsync(client, customer.Id, product.Id, 2, 5000, saleDate: "2026-10-02");
        await CreateSaleAsync(client, customer.Id, product.Id, 3, 5000, saleDate: "2026-10-10");

        var report = await client.GetFromJsonAsync<SalesReportDto>(
            "/api/reports/sales?dateFrom=2026-10-01&dateTo=2026-10-03", JsonOptions);

        Assert.NotNull(report);
        Assert.Equal(2, report.Totals.Count);          // 10-03 is excluded
        Assert.Equal(15000, report.Totals.Subtotal);   // 5000 + 10000
        Assert.Equal(3, report.Series.Count);          // three daily buckets
        Assert.Equal(5000, report.Series[0].Sales);
        Assert.Equal(10000, report.Series[1].Sales);
        Assert.Equal(0, report.Series[2].Sales);       // no sales that day
    }

    [Fact]
    public async Task Report_DateRangeIsInclusiveOnBothEnds()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 1000, 2000, 0, 100);
        var customer = await CreateCustomerAsync(client);

        await CreateSaleAsync(client, customer.Id, product.Id, 1, 2000, saleDate: "2026-10-01");
        await CreateSaleAsync(client, customer.Id, product.Id, 1, 2000, saleDate: "2026-10-05");
        await CreateSaleAsync(client, customer.Id, product.Id, 1, 2000, saleDate: "2026-10-06");

        // Both endpoints included.
        var exact = await GetSalesReportAsync(client, "2026-10-01", "2026-10-05");
        Assert.Equal(2, exact.Totals.Count);
        Assert.Equal(4000, exact.Totals.Subtotal);

        // A single-day range includes that day only.
        var single = await GetSalesReportAsync(client, "2026-10-05", "2026-10-05");
        Assert.Equal(1, single.Totals.Count);
        Assert.Single(single.Series);

        // An empty range returns zeros, not an error.
        var empty = await GetSalesReportAsync(client, "2026-10-20", "2026-10-25");
        Assert.Equal(0, empty.Totals.Count);
        Assert.Equal(0, empty.Totals.Total);
    }

    [Fact]
    public async Task SalesReport_GroupsByWeekAndMonth()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 1000, 2000, 0, 200);
        var customer = await CreateCustomerAsync(client);

        await CreateSaleAsync(client, customer.Id, product.Id, 1, 2000, saleDate: "2026-10-01");
        await CreateSaleAsync(client, customer.Id, product.Id, 1, 2000, saleDate: "2026-10-02");
        await CreateSaleAsync(client, customer.Id, product.Id, 1, 2000, saleDate: "2026-11-15");

        var monthly = await GetSalesReportAsync(client, "2026-10-01", "2026-11-30", "month");
        Assert.Equal(2, monthly.Series.Count);                 // Oct and Nov
        Assert.Equal(4000, monthly.Series[0].Sales);
        Assert.Equal(2000, monthly.Series[1].Sales);
        Assert.Equal(6000, monthly.Series.Sum(p => p.Sales));

        var weekly = await GetSalesReportAsync(client, "2026-10-01", "2026-11-30", "week");
        Assert.True(weekly.Series.Count < monthly.Series.Count + 9,
            "weekly buckets should be fewer than daily buckets");
        Assert.Equal(6000, weekly.Series.Sum(p => p.Sales));

        // Weekly buckets always start on a Monday.
        Assert.All(weekly.Series, p => Assert.Equal(DayOfWeek.Monday, p.Date.DayOfWeek));
    }

    [Fact]
    public async Task SalesReport_ReturnsTopProductsAndCustomers()
    {
        var client = await CreateOwnerClientAsync();
        var rice = await CreateProductAsync(client, 1000, 10000, 0, 100, name: "Basmati Rice");
        var oil = await CreateProductAsync(client, 500, 3000, 0, 100, name: "Sunflower Oil");
        var big = await CreateCustomerAsync(client, "Big Buyer");
        var small = await CreateCustomerAsync(client, "Small Buyer");

        await CreateSaleAsync(client, big.Id, rice.Id, 5, 10000);    // 50000
        await CreateSaleAsync(client, big.Id, oil.Id, 2, 3000);      // 6000
        await CreateSaleAsync(client, small.Id, oil.Id, 1, 3000);    // 3000

        var report = await GetSalesReportAsync(client, "2026-01-01", "2026-12-31");

        Assert.Equal(2, report.TopProducts.Count);
        Assert.Equal("Basmati Rice", report.TopProducts[0].Name);
        Assert.Equal(50000, report.TopProducts[0].Amount);
        Assert.Equal(5, report.TopProducts[0].Quantity);
        Assert.Equal(1, report.TopProducts[0].Count);       // one sale line

        // Oil appears on two sale lines, so its count is 2 while its amount is smaller.
        Assert.Equal("Sunflower Oil", report.TopProducts[1].Name);
        Assert.Equal(9000, report.TopProducts[1].Amount);
        Assert.Equal(3, report.TopProducts[1].Quantity);
        Assert.Equal(2, report.TopProducts[1].Count);

        Assert.Equal(2, report.TopCustomers.Count);
        Assert.Equal("Big Buyer", report.TopCustomers[0].Name);
        Assert.Equal(56000, report.TopCustomers[0].Amount);
    }

    // --- expense / stock / balances ---

    [Fact]
    public async Task ExpenseReport_GroupsByCategory()
    {
        var client = await CreateOwnerClientAsync();
        await CreateExpenseAsync(client, "Rent", 250000);
        await CreateExpenseAsync(client, "Rent", 250000);
        await CreateExpenseAsync(client, "Salary", 600000);

        var report = await client.GetFromJsonAsync<ExpenseReportDto>(
            "/api/reports/expenses?dateFrom=2026-01-01&dateTo=2026-12-31", JsonOptions);

        Assert.NotNull(report);
        Assert.Equal(1100000, report.Total);
        Assert.Equal(3, report.Count);
        Assert.Equal(2, report.ByCategory.Count);
        Assert.Equal("Salary", report.ByCategory[0].Category);
        Assert.Equal(600000, report.ByCategory[0].Amount);
        Assert.Equal("Rent", report.ByCategory[1].Category);
        Assert.Equal(500000, report.ByCategory[1].Amount);
        Assert.Equal(2, report.ByCategory[1].Count);
    }

    [Fact]
    public async Task StockReport_ValuatesStockAndFlagsLowStock()
    {
        var client = await CreateOwnerClientAsync();
        await CreateProductAsync(client, 5000, 8000, 0, 10, name: "Plenty");
        await CreateProductAsync(client, 2000, 3000, 0, 2, name: "Scarce", minQuantity: 5);

        var report = await client.GetFromJsonAsync<StockReportDto>("/api/reports/stock", JsonOptions);

        Assert.NotNull(report);
        Assert.Equal(2, report.ProductCount);
        Assert.Equal((10 * 5000) + (2 * 2000), report.TotalCostValue);
        Assert.Equal((10 * 8000) + (2 * 3000), report.TotalRetailValue);
        Assert.Equal(1, report.LowStockCount);

        var scarce = report.Items.Single(i => i.Name == "Scarce");
        Assert.True(scarce.IsLowStock);
        Assert.Equal(4000, scarce.CostValue);

        var lowOnly = await client.GetFromJsonAsync<StockReportDto>(
            "/api/reports/stock?lowStockOnly=true", JsonOptions);
        Assert.Single(lowOnly!.Items);
        Assert.Equal("Scarce", lowOnly.Items[0].Name);

        // The low-stock count is business-wide even when filtering.
        Assert.Equal(1, lowOnly.LowStockCount);
    }

    [Fact]
    public async Task ReceivablePayableReport_ListsOutstandingParties()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client, "Owed Customer", openingBalance: 30000);
        var other = await CreateCustomerAsync(client, "Settled Customer", openingBalance: 0);
        var supplier = await CreateSupplierAsync(client, "Owed Supplier", openingBalance: 25000);

        var report = await client.GetFromJsonAsync<ReceivablePayableReportDto>(
            "/api/reports/receivable-payable", JsonOptions);

        Assert.NotNull(report);
        Assert.Equal(30000, report.TotalReceivable);
        Assert.Equal(25000, report.TotalPayable);

        var receivable = Assert.Single(report.Receivables);
        Assert.Equal("Owed Customer", receivable.Name);
        Assert.Equal(30000, receivable.Balance);

        var payable = Assert.Single(report.Payables);
        Assert.Equal("Owed Supplier", payable.Name);

        Assert.DoesNotContain(report.Receivables, p => p.PartyId == other.Id);
        Assert.Equal(customer.Id, receivable.PartyId);
        Assert.Equal(supplier.Id, payable.PartyId);
    }

    // --- validation + export ---

    [Fact]
    public async Task Report_WithReversedRange_Returns422()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.GetAsync("/api/reports/sales?dateFrom=2026-10-10&dateTo=2026-10-01");

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task Report_WithTooLargeARange_Returns422()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.GetAsync("/api/reports/sales?dateFrom=2020-01-01&dateTo=2030-01-01");

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task Report_WithInvalidGroupBy_Returns422()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.GetAsync("/api/reports/sales?dateFrom=2026-10-01&dateTo=2026-10-31&groupBy=quarter");

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task Export_SalesCsv_ReturnsADownloadableCsv()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 4000, 5000, 0, 10);
        var customer = await CreateCustomerAsync(client, "Hari, \"The\" Buyer");
        var sale = await CreateSaleAsync(client, customer.Id, product.Id, 2, 5000);

        var response = await client.GetAsync(
            "/api/reports/export?type=sales&dateFrom=2026-01-01&dateTo=2026-12-31");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("text/csv", response.Content.Headers.ContentType?.MediaType);
        Assert.Contains("sales-", response.Content.Headers.ContentDisposition?.FileName);

        var bytes = await response.Content.ReadAsByteArrayAsync();
        Assert.Equal([0xEF, 0xBB, 0xBF], bytes.Take(3).ToArray());   // UTF-8 BOM for Excel

        var text = Encoding.UTF8.GetString(bytes);
        Assert.Contains("Invoice,Date,Customer,Type,Status", text);
        Assert.Contains(sale.InvoiceNumber, text);
        // A customer name with a comma and quotes must be escaped properly.
        Assert.Contains("\"Hari, \"\"The\"\" Buyer\"", text);
        Assert.Contains("100.00", text);   // 10000 paisa
    }

    [Fact]
    public async Task Export_ProfitLossAndStock_ProduceCsv()
    {
        var client = await CreateOwnerClientAsync();
        await CreateProductAsync(client, 4000, 5000, 0, 10, name: "Item One");

        var pl = await client.GetAsync("/api/reports/export?type=profit-loss&dateFrom=2026-01-01&dateTo=2026-12-31");
        Assert.Equal(HttpStatusCode.OK, pl.StatusCode);
        var plText = Encoding.UTF8.GetString(await pl.Content.ReadAsByteArrayAsync());
        Assert.Contains("Net profit", plText);
        Assert.Contains("Cost of goods sold", plText);

        var stock = await client.GetAsync("/api/reports/export?type=stock&dateFrom=2026-01-01&dateTo=2026-12-31");
        Assert.Equal(HttpStatusCode.OK, stock.StatusCode);
        var stockText = Encoding.UTF8.GetString(await stock.Content.ReadAsByteArrayAsync());
        Assert.Contains("Product,Category,Unit,Quantity", stockText);
        Assert.Contains("Item One", stockText);
    }

    [Fact]
    public async Task Export_WithUnknownType_Returns422()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.GetAsync(
            "/api/reports/export?type=whatever&dateFrom=2026-10-01&dateTo=2026-10-31");

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    // --- isolation ---

    [Fact]
    public async Task OtherBusiness_SeesOnlyItsOwnFigures()
    {
        var ownerA = await CreateOwnerClientAsync();
        var productA = await CreateProductAsync(ownerA, 1000, 5000, 0, 100);
        var customerA = await CreateCustomerAsync(ownerA);
        await CreateSaleAsync(ownerA, customerA.Id, productA.Id, 4, 5000);

        var ownerB = await CreateOwnerClientAsync();

        var dashboard = await ownerB.GetFromJsonAsync<DashboardDto>("/api/reports/dashboard", JsonOptions);
        Assert.Equal(0, dashboard!.TodaySales.Count);
        Assert.Equal(0, dashboard.StockCostValue);
        Assert.Equal(0, dashboard.TotalReceivable);
        Assert.Empty(dashboard.TopProducts);

        var report = await GetSalesReportAsync(ownerB, "2026-01-01", "2026-12-31");
        Assert.Equal(0, report.Totals.Count);
    }

    // --- helpers ---

    private static async Task<SalesReportDto> GetSalesReportAsync(
        HttpClient client, string from, string to, string groupBy = "day")
    {
        var url = $"/api/reports/sales?dateFrom={from}&dateTo={to}&groupBy={groupBy}";
        return (await client.GetFromJsonAsync<SalesReportDto>(url, JsonOptions))!;
    }

    private static async Task<SaleDto> CreateSaleAsync(
        HttpClient client, long customerId, long productId, decimal quantity, long unitPrice,
        string saleType = "Credit", string? saleDate = null)
    {
        // Defaults to a credit sale: a cash sale must be paid to the exact total
        // *including tax*, which the caller cannot compute from these arguments.
        var paid = saleType == "Credit" ? 0L : (long)Math.Round(quantity * unitPrice);
        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            customerId,
            saleType,
            saleDate,
            items = new[] { new { productId, quantity, unitPrice } },
            paidAmount = paid,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SaleDto>(JsonOptions))!;
    }

    private static async Task CreateExpenseAsync(HttpClient client, string category, long amount)
    {
        var response = await client.PostAsJsonAsync("/api/expenses", new { category, amount });
        response.EnsureSuccessStatusCode();
    }

    private static async Task CreateIncomeAsync(HttpClient client, string source, long amount)
    {
        var response = await client.PostAsJsonAsync("/api/incomes", new { source, amount });
        response.EnsureSuccessStatusCode();
    }

    private static async Task<ProductDto> CreateProductAsync(
        HttpClient client, long costPrice, long sellingPrice, int taxRateBps,
        double openingQuantity, string? name = null, double minQuantity = 0)
    {
        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name = name ?? $"P {Guid.NewGuid():n}",
            costPrice,
            sellingPrice,
            taxRateBps,
            openingQuantity,
            minQuantity,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ProductDto>(JsonOptions))!;
    }

    private static async Task<CustomerDto> CreateCustomerAsync(
        HttpClient client, string? name = null, long openingBalance = 0)
    {
        var response = await client.PostAsJsonAsync("/api/customers", new
        {
            name = name ?? $"C {Guid.NewGuid():n}",
            openingBalance,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<CustomerDto>(JsonOptions))!;
    }

    private static async Task<SupplierDto> CreateSupplierAsync(
        HttpClient client, string name, long openingBalance = 0)
    {
        var response = await client.PostAsJsonAsync("/api/suppliers", new { name, openingBalance });
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
