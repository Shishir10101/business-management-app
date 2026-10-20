namespace Khata.Infrastructure.Services;

using System.Globalization;
using FluentValidation;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// CSV import for products and customers — the onboarding path for a shop that
/// already keeps its catalog in Excel.
/// </summary>
/// <remarks>
/// Validation is NOT re-implemented here: every row is turned into the same
/// <see cref="CreateProductRequest"/> / <see cref="CreateCustomerRequest"/> the
/// REST endpoints accept and handed to the SAME FluentValidation validator, so
/// an import can never accept a row the API would reject. On top of that the
/// importer adds spreadsheet concerns: header aliases, money in rupees,
/// tax as a percentage, and duplicate detection.
/// </remarks>
public class ImportService : IImportService
{
    /// <summary>Rows accepted in one file. Beyond this the client should split it.</summary>
    public const int MaxRows = 5000;

    /// <summary>Characters accepted in one file (~2 MB of text).</summary>
    public const int MaxCharacters = 2_000_000;

    /// <summary>Row issues returned per response; the rest are summarized by count.</summary>
    public const int MaxIssuesReported = 200;

    public const string ProductsEntity = "products";
    public const string CustomersEntity = "customers";

    private static readonly string[] ProductNameColumns =
        ["name", "productname", "product", "item", "itemname", "title", "नाम", "सामान"];

    private static readonly string[] ProductSkuColumns =
        ["sku", "code", "productcode", "itemcode", "skucode"];

    private static readonly string[] ProductBarcodeColumns =
        ["barcode", "barcodenumber", "ean", "upc"];

    private static readonly string[] ProductCategoryColumns =
        ["category", "categoryname", "group", "वर्ग"];

    private static readonly string[] ProductUnitColumns =
        ["unit", "unitname", "uom", "unitofmeasure", "इकाई"];

    private static readonly string[] ProductCostColumns =
        ["costprice", "cost", "purchaseprice", "buyprice", "खरिदमूल्य"];

    private static readonly string[] ProductSellingColumns =
        ["sellingprice", "price", "saleprice", "selling", "mrp", "बिक्रीमूल्य", "मूल्य"];

    private static readonly string[] ProductWholesaleColumns =
        ["wholesaleprice", "wholesale", "thokprice"];

    private static readonly string[] ProductTaxColumns =
        ["taxrate", "tax", "vat", "vatrate", "taxpercent", "कर"];

    private static readonly string[] ProductQuantityColumns =
        ["openingquantity", "openingstock", "quantity", "qty", "stock", "परिमाण", "मात्रा"];

    private static readonly string[] ProductMinQuantityColumns =
        ["minquantity", "minstock", "reorderlevel", "reorder", "minimumquantity"];

    private static readonly string[] ProductDescriptionColumns =
        ["description", "notes", "remarks", "detail", "विवरण"];

    private static readonly string[] CustomerNameColumns =
        ["name", "customername", "customer", "party", "partyname", "ग्राहक", "नाम"];

    private static readonly string[] CustomerPhoneColumns =
        ["phone", "phonenumber", "mobile", "mobilenumber", "contact", "contactnumber", "फोन", "मोबाइल"];

    private static readonly string[] CustomerEmailColumns =
        ["email", "emailaddress", "इमेल"];

    private static readonly string[] CustomerAddressColumns =
        ["address", "addressline", "location", "ठेगाना"];

    private static readonly string[] CustomerCityColumns = ["city", "town", "शहर"];

    private static readonly string[] CustomerDistrictColumns = ["district", "जिल्ला"];

    private static readonly string[] CustomerOpeningColumns =
        ["openingbalance", "opening", "balance", "due", "openingdue", "outstanding", "बाँकी"];

    private static readonly string[] CustomerPanColumns =
        ["pan", "pannumber", "vatno", "vatnumber", "प्यान"];

    private static readonly string[] CustomerCreditLimitColumns =
        ["creditlimit", "credit", "limit", "सीमा"];

    private static readonly string[] CustomerNotesColumns =
        ["notes", "remarks", "description", "कैफियत"];

    private static readonly Dictionary<string, string> ProductColumnLabels = new()
    {
        ["Name"] = "name",
        ["Sku"] = "sku",
        ["Barcode"] = "barcode",
        ["Description"] = "description",
        ["CostPrice"] = "costPrice",
        ["SellingPrice"] = "sellingPrice",
        ["WholesalePrice"] = "wholesalePrice",
        ["TaxRateBps"] = "taxRate",
        ["OpeningQuantity"] = "openingQuantity",
        ["MinQuantity"] = "minQuantity",
    };

    private static readonly Dictionary<string, string> CustomerColumnLabels = new()
    {
        ["Name"] = "name",
        ["PhoneNumber"] = "phone",
        ["Email"] = "email",
        ["AddressLine"] = "address",
        ["City"] = "city",
        ["District"] = "district",
        ["OpeningBalance"] = "openingBalance",
        ["PanNumber"] = "pan",
        ["CreditLimit"] = "creditLimit",
        ["Notes"] = "notes",
    };

    private readonly KhataDbContext _db;
    private readonly IProductService _products;
    private readonly IPartyService _parties;
    private readonly ICurrentUserService _currentUser;
    private readonly IValidator<CreateProductRequest> _productValidator;
    private readonly IValidator<CreateCustomerRequest> _customerValidator;

    public ImportService(
        KhataDbContext db,
        IProductService products,
        IPartyService parties,
        ICurrentUserService currentUser,
        IValidator<CreateProductRequest> productValidator,
        IValidator<CreateCustomerRequest> customerValidator)
    {
        _db = db;
        _products = products;
        _parties = parties;
        _currentUser = currentUser;
        _productValidator = productValidator;
        _customerValidator = customerValidator;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    // --- Products ---

    public async Task<ImportPreviewDto> PreviewProductsAsync(
        string csv,
        CancellationToken cancellationToken = default)
    {
        var analysis = await AnalyzeProductsAsync(csv, cancellationToken);
        return analysis.Preview;
    }

    public async Task<ImportOutcomeDto> ImportProductsAsync(
        string csv,
        CancellationToken cancellationToken = default)
    {
        var analysis = await AnalyzeProductsAsync(csv, cancellationToken);
        if (analysis.Preview.InvalidRows > 0)
            return new ImportOutcomeDto(null, analysis.Preview);

        var created = 0;
        var skipped = 0;

        await using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            // Categories named in the file but missing from the catalog are
            // created (a category is just a grouping label). Units are NOT
            // auto-created: they change what a quantity MEANS, so the file must
            // use one that already exists.
            var newCategories = new List<(string Name, ProductCategory Entity)>();
            foreach (var name in analysis.NewCategories)
            {
                var entity = new ProductCategory { BusinessId = BusinessId, Name = name };
                _db.ProductCategories.Add(entity);
                newCategories.Add((name, entity));
            }
            if (newCategories.Count > 0) await _db.SaveChangesAsync(cancellationToken);

            foreach (var plan in analysis.Plans)
            {
                if (plan.IsDuplicate)
                {
                    skipped++;
                    continue;
                }

                var request = plan.Request;
                if (plan.CategoryName is { } categoryName)
                {
                    var match = newCategories.FirstOrDefault(
                        c => string.Equals(c.Name, categoryName, StringComparison.OrdinalIgnoreCase));
                    if (match.Entity is not null) request = request with { CategoryId = match.Entity.Id };
                }

                await _products.CreateProductAsync(request, cancellationToken);
                created++;
            }

            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            // Nothing is left half-written: the whole file is one transaction.
            await transaction.RollbackAsync(CancellationToken.None);
            throw;
        }

        return new ImportOutcomeDto(
            new ImportResultDto(ProductsEntity, created, skipped, []),
            null);
    }

    public CsvExportDto ProductTemplate() => new(
        "khata-products-template.csv",
        "name,sku,barcode,category,unit,costPrice,sellingPrice,wholesalePrice,taxRate,openingQuantity,minQuantity,description\r\n");

    private async Task<ProductAnalysis> AnalyzeProductsAsync(
        string csv,
        CancellationToken cancellationToken)
    {
        var table = CsvTable.Parse(csv);
        if (Guard(table, csv, ProductsEntity, out var guarded))
            return new ProductAnalysis(guarded!, [], []);

        var used = new HashSet<int>();
        int? Col(params string[] aliases)
        {
            var index = table.IndexOf(aliases);
            if (index is { } i) used.Add(i);
            return index;
        }

        var nameCol = Col(ProductNameColumns);
        var skuCol = Col(ProductSkuColumns);
        var barcodeCol = Col(ProductBarcodeColumns);
        var categoryCol = Col(ProductCategoryColumns);
        var unitCol = Col(ProductUnitColumns);
        var costCol = Col(ProductCostColumns);
        var sellingCol = Col(ProductSellingColumns);
        var wholesaleCol = Col(ProductWholesaleColumns);
        var taxCol = Col(ProductTaxColumns);
        var quantityCol = Col(ProductQuantityColumns);
        var minQuantityCol = Col(ProductMinQuantityColumns);
        var descriptionCol = Col(ProductDescriptionColumns);

        if (nameCol is null)
        {
            return new ProductAnalysis(
                MissingColumn(
                    table, ProductsEntity, "name",
                    "The file needs a name column. Download the template to see the expected headers."),
                [],
                []);
        }

        var categories = await _db.ProductCategories
            .Where(c => c.DeletedAt == null)
            .Select(c => new { c.Id, c.Name })
            .ToListAsync(cancellationToken);
        var categoryIds = new Dictionary<string, long>();
        foreach (var category in categories)
            categoryIds.TryAdd(CsvTable.Normalize(category.Name), category.Id);

        var units = await _db.Units
            .Where(u => u.DeletedAt == null)
            .Select(u => new { u.Id, u.Name, u.ShortName })
            .ToListAsync(cancellationToken);
        var unitIds = new Dictionary<string, long>();
        foreach (var unit in units)
        {
            unitIds.TryAdd(CsvTable.Normalize(unit.Name), unit.Id);
            unitIds.TryAdd(CsvTable.Normalize(unit.ShortName), unit.Id);
        }
        var unitHint = string.Join(", ", units.Select(u => u.ShortName));

        var existingKeys = (await _db.Products
                .Where(p => p.DeletedAt == null)
                .Select(p => new { p.Sku, p.Name })
                .ToListAsync(cancellationToken))
            .Select(p => ProductKey(p.Sku, p.Name))
            .ToHashSet();

        // Barcodes are unique per business (the product service rejects a
        // duplicate with a 409). Checking them here turns that 409 into a row
        // error with a line number, before anything is written.
        var existingBarcodes = (await _db.Products
                .Where(p => p.DeletedAt == null && p.Barcode != null)
                .Select(p => p.Barcode!)
                .ToListAsync(cancellationToken))
            .Select(b => b.Trim().ToLowerInvariant())
            .ToHashSet();

        var issues = new List<ImportIssueDto>();
        var plans = new List<ProductPlan>();
        var newCategories = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var seen = new HashSet<string>(StringComparer.Ordinal);
        var seenBarcodes = new HashSet<string>(StringComparer.Ordinal);
        var valid = 0;
        var duplicates = 0;
        var invalid = 0;

        foreach (var record in table.Rows)
        {
            var row = record.Number;
            var rowIssues = new List<ImportIssueDto>();

            var name = CsvTable.Value(record, nameCol) ?? string.Empty;

            var cost = 0L;
            if (!TryMoney(CsvTable.Value(record, costCol), out cost, out var costError))
                rowIssues.Add(new ImportIssueDto(row, "costPrice", costError!));

            var selling = 0L;
            if (!TryMoney(CsvTable.Value(record, sellingCol), out selling, out var sellingError))
                rowIssues.Add(new ImportIssueDto(row, "sellingPrice", sellingError!));

            long? wholesale = null;
            var wholesaleRaw = CsvTable.Value(record, wholesaleCol);
            if (wholesaleRaw is not null)
            {
                if (TryMoney(wholesaleRaw, out var parsed, out var wholesaleError))
                    wholesale = parsed;
                else
                    rowIssues.Add(new ImportIssueDto(row, "wholesalePrice", wholesaleError!));
            }

            var tax = 0;
            if (!TryPercent(CsvTable.Value(record, taxCol), out tax, out var taxError))
                rowIssues.Add(new ImportIssueDto(row, "taxRate", taxError!));

            var quantity = 0m;
            if (!TryQuantity(CsvTable.Value(record, quantityCol), out quantity, out var quantityError))
                rowIssues.Add(new ImportIssueDto(row, "openingQuantity", quantityError!));

            var minQuantity = 0m;
            if (!TryQuantity(CsvTable.Value(record, minQuantityCol), out minQuantity, out var minError))
                rowIssues.Add(new ImportIssueDto(row, "minQuantity", minError!));

            long? categoryId = null;
            string? categoryName = null;
            var categoryRaw = CsvTable.Value(record, categoryCol);
            if (categoryRaw is not null)
            {
                if (categoryIds.TryGetValue(CsvTable.Normalize(categoryRaw), out var id))
                {
                    categoryId = id;
                }
                else
                {
                    categoryName = categoryRaw;
                    newCategories.Add(categoryRaw);
                }
            }

            long? unitId = null;
            var unitRaw = CsvTable.Value(record, unitCol);
            if (unitRaw is not null)
            {
                if (unitIds.TryGetValue(CsvTable.Normalize(unitRaw), out var id))
                    unitId = id;
                else
                    rowIssues.Add(new ImportIssueDto(
                        row, "unit",
                        $"Unknown unit '{unitRaw}'. Add it under Units first, or use one of: {unitHint}."));
            }

            var sku = CsvTable.Value(record, skuCol);
            var request = new CreateProductRequest(
                Name: name,
                CategoryId: categoryId,
                UnitId: unitId,
                Sku: sku,
                Barcode: CsvTable.Value(record, barcodeCol),
                Description: CsvTable.Value(record, descriptionCol),
                CostPrice: cost,
                SellingPrice: selling,
                WholesalePrice: wholesale,
                TaxRateBps: tax,
                IsActive: true,
                OpeningQuantity: quantity,
                MinQuantity: minQuantity);

            // Same rules as POST /api/products — one source of truth.
            var validation = await _productValidator.ValidateAsync(request, cancellationToken);
            foreach (var failure in validation.Errors)
            {
                rowIssues.Add(new ImportIssueDto(
                    row,
                    ColumnLabel(ProductColumnLabels, failure.PropertyName),
                    failure.ErrorMessage));
            }

            if (rowIssues.Count > 0)
            {
                invalid++;
                AddIssues(issues, rowIssues);
                continue;
            }

            var key = ProductKey(sku, name);
            var isExisting = existingKeys.Contains(key);
            var isRepeated = seen.Contains(key);

            // A barcode shared with another product is a data error, not a
            // duplicate — but only for rows that are genuinely new. Re-running
            // the same file must still skip its own barcodes.
            if (!isExisting && !isRepeated && request.Barcode is { } barcode)
            {
                var normalizedBarcode = barcode.Trim().ToLowerInvariant();
                if (existingBarcodes.Contains(normalizedBarcode) ||
                    !seenBarcodes.Add(normalizedBarcode))
                {
                    invalid++;
                    AddIssues(issues,
                    [
                        new ImportIssueDto(
                            row, "barcode",
                            $"Barcode '{barcode}' is already used by another product."),
                    ]);
                    continue;
                }
            }

            var isDuplicate = isExisting || isRepeated;
            if (isDuplicate)
            {
                duplicates++;
            }
            else
            {
                valid++;
                seen.Add(key);
            }

            plans.Add(new ProductPlan(request, categoryName, isDuplicate));
        }

        return new ProductAnalysis(
            new ImportPreviewDto(
                ProductsEntity,
                table.Rows.Count,
                valid,
                duplicates,
                invalid,
                Columns(table, used),
                IgnoredColumns(table, used),
                issues),
            plans,
            newCategories);
    }

    // --- Customers ---

    public async Task<ImportPreviewDto> PreviewCustomersAsync(
        string csv,
        CancellationToken cancellationToken = default)
    {
        var analysis = await AnalyzeCustomersAsync(csv, cancellationToken);
        return analysis.Preview;
    }

    public async Task<ImportOutcomeDto> ImportCustomersAsync(
        string csv,
        CancellationToken cancellationToken = default)
    {
        var analysis = await AnalyzeCustomersAsync(csv, cancellationToken);
        if (analysis.Preview.InvalidRows > 0)
            return new ImportOutcomeDto(null, analysis.Preview);

        var created = 0;
        var skipped = 0;

        await using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            foreach (var plan in analysis.Plans)
            {
                if (plan.IsDuplicate)
                {
                    skipped++;
                    continue;
                }

                // A customer with an opening balance gets its ledger account and
                // opening entry from the party service — the khata stays correct.
                await _parties.CreateCustomerAsync(plan.Request, cancellationToken);
                created++;
            }

            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(CancellationToken.None);
            throw;
        }

        return new ImportOutcomeDto(
            new ImportResultDto(CustomersEntity, created, skipped, []),
            null);
    }

    public CsvExportDto CustomerTemplate() => new(
        "khata-customers-template.csv",
        "name,phone,email,address,city,district,pan,openingBalance,creditLimit,notes\r\n");

    private async Task<CustomerAnalysis> AnalyzeCustomersAsync(
        string csv,
        CancellationToken cancellationToken)
    {
        var table = CsvTable.Parse(csv);
        if (Guard(table, csv, CustomersEntity, out var guarded)) return new CustomerAnalysis(guarded!, []);

        var used = new HashSet<int>();
        int? Col(params string[] aliases)
        {
            var index = table.IndexOf(aliases);
            if (index is { } i) used.Add(i);
            return index;
        }

        var nameCol = Col(CustomerNameColumns);
        var phoneCol = Col(CustomerPhoneColumns);
        var emailCol = Col(CustomerEmailColumns);
        var addressCol = Col(CustomerAddressColumns);
        var cityCol = Col(CustomerCityColumns);
        var districtCol = Col(CustomerDistrictColumns);
        var openingCol = Col(CustomerOpeningColumns);
        var panCol = Col(CustomerPanColumns);
        var creditLimitCol = Col(CustomerCreditLimitColumns);
        var notesCol = Col(CustomerNotesColumns);

        if (nameCol is null)
        {
            return new CustomerAnalysis(
                MissingColumn(
                    table, CustomersEntity, "name",
                    "The file needs a name column. Download the template to see the expected headers."),
                []);
        }

        var existingKeys = (await _db.Customers
                .Where(c => c.DeletedAt == null)
                .Select(c => new { c.Name, c.PhoneNumber })
                .ToListAsync(cancellationToken))
            .Select(c => CustomerKey(c.Name, c.PhoneNumber))
            .ToHashSet();

        var issues = new List<ImportIssueDto>();
        var plans = new List<CustomerPlan>();
        var seen = new HashSet<string>(StringComparer.Ordinal);
        var valid = 0;
        var duplicates = 0;
        var invalid = 0;

        foreach (var record in table.Rows)
        {
            var row = record.Number;
            var rowIssues = new List<ImportIssueDto>();

            var name = CsvTable.Value(record, nameCol) ?? string.Empty;
            var phone = CsvTable.Value(record, phoneCol);

            var openingBalance = 0L;
            if (!TryMoney(CsvTable.Value(record, openingCol), out openingBalance, out var openingError))
                rowIssues.Add(new ImportIssueDto(row, "openingBalance", openingError!));

            long? creditLimit = null;
            var creditLimitRaw = CsvTable.Value(record, creditLimitCol);
            if (creditLimitRaw is not null)
            {
                if (TryMoney(creditLimitRaw, out var parsed, out var creditError))
                    creditLimit = parsed;
                else
                    rowIssues.Add(new ImportIssueDto(row, "creditLimit", creditError!));
            }

            var request = new CreateCustomerRequest(
                Name: name,
                PhoneNumber: phone,
                Email: CsvTable.Value(record, emailCol),
                AddressLine: CsvTable.Value(record, addressCol),
                City: CsvTable.Value(record, cityCol),
                District: CsvTable.Value(record, districtCol),
                OpeningBalance: openingBalance,
                PanNumber: CsvTable.Value(record, panCol),
                CreditLimit: creditLimit,
                Notes: CsvTable.Value(record, notesCol),
                IsActive: true);

            var validation = await _customerValidator.ValidateAsync(request, cancellationToken);
            foreach (var failure in validation.Errors)
            {
                rowIssues.Add(new ImportIssueDto(
                    row,
                    ColumnLabel(CustomerColumnLabels, failure.PropertyName),
                    failure.ErrorMessage));
            }

            if (rowIssues.Count > 0)
            {
                invalid++;
                AddIssues(issues, rowIssues);
                continue;
            }

            var key = CustomerKey(name, phone);
            var isDuplicate = existingKeys.Contains(key) || !seen.Add(key);
            if (isDuplicate) duplicates++;
            else valid++;

            plans.Add(new CustomerPlan(request, isDuplicate));
        }

        return new CustomerAnalysis(
            new ImportPreviewDto(
                CustomersEntity,
                table.Rows.Count,
                valid,
                duplicates,
                invalid,
                Columns(table, used),
                IgnoredColumns(table, used),
                issues),
            plans);
    }

    // --- Shared helpers ---

    /// <summary>
    /// Rejects a file that cannot be analyzed at all (empty, too big, too many
    /// rows). Returns true when <paramref name="preview"/> holds the refusal.
    /// </summary>
    private static bool Guard(
        CsvTable table,
        string? csv,
        string entity,
        out ImportPreviewDto? preview)
    {
        preview = null;

        // Null covers a caller that skipped model binding; the API itself
        // rejects a null `csv` with a 400 before this runs.
        if (string.IsNullOrEmpty(csv) || table.Headers.Count == 0 || table.Rows.Count == 0)
        {
            preview = Refused(entity, 0, "The file is empty — it needs a header row and at least one data row.");
            return true;
        }

        if (csv.Length > MaxCharacters)
        {
            preview = Refused(
                entity, 0,
                $"The file is larger than {MaxCharacters / 1_000_000} MB. Split it into smaller files.");
            return true;
        }

        if (table.Rows.Count > MaxRows)
        {
            preview = Refused(
                entity, table.Rows.Count,
                $"The file has {table.Rows.Count} rows; the limit is {MaxRows} per import. Split it into smaller files.");
            return true;
        }

        return false;
    }

    /// <summary>A refusal with <c>InvalidRows = 1</c>, so an import will not run.</summary>
    private static ImportPreviewDto Refused(string entity, int totalRows, string message)
        => new(
            entity,
            totalRows,
            0,
            0,
            1,
            [],
            [],
            [new ImportIssueDto(1, null, message)]);

    private static ImportPreviewDto MissingColumn(
        CsvTable table,
        string entity,
        string column,
        string message)
        => new(
            entity,
            table.Rows.Count,
            0,
            0,
            1,
            [],
            [],
            [new ImportIssueDto(1, column, message)]);

    private static void AddIssues(List<ImportIssueDto> target, List<ImportIssueDto> rowIssues)
    {
        if (target.Count >= MaxIssuesReported) return;
        var room = MaxIssuesReported - target.Count;
        target.AddRange(rowIssues.Take(room));
    }

    private static IReadOnlyList<string> Columns(CsvTable table, HashSet<int> used)
        => table.Headers
            .Where((_, index) => used.Contains(index))
            .Select(h => h.Trim())
            .Where(h => h.Length > 0)
            .ToList();

    private static IReadOnlyList<string> IgnoredColumns(CsvTable table, HashSet<int> used)
        => table.Headers
            .Where((_, index) => !used.Contains(index))
            .Select(h => h.Trim())
            .Where(h => h.Length > 0)
            .ToList();

    private static string? ColumnLabel(Dictionary<string, string> labels, string? propertyName)
        => propertyName is not null && labels.TryGetValue(propertyName, out var label)
            ? label
            : propertyName;

    /// <summary>
    /// Identity of a product for duplicate detection: the SKU when the row has
    /// one (it is the business key), otherwise the name.
    /// </summary>
    private static string ProductKey(string? sku, string name)
        => string.IsNullOrWhiteSpace(sku)
            ? "name:" + CsvTable.Normalize(name)
            : "sku:" + CsvTable.Normalize(sku);

    /// <summary>
    /// Identity of a customer for duplicate detection: name plus the digits of
    /// the phone. Two entries for the same name with different phones are
    /// different people; the same name with no phone is a duplicate.
    /// </summary>
    private static string CustomerKey(string name, string? phone)
        => CsvTable.Normalize(name) + "|" + Digits(phone);

    private static string Digits(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return string.Empty;
        return new string(value.Where(char.IsDigit).ToArray());
    }

    /// <summary>
    /// Spreadsheet money ("Rs 1,234.50", "1234", "1 234") to integer paisa.
    /// Rounds half away from zero; negative amounts are allowed here and
    /// rejected by the validator, so the user sees the API's own message.
    /// </summary>
    private static bool TryMoney(string? raw, out long paisa, out string? error)
    {
        paisa = 0;
        error = null;
        if (string.IsNullOrWhiteSpace(raw)) return true;

        var cleaned = CleanNumber(raw);
        if (cleaned.Length == 0 || !decimal.TryParse(
                cleaned, NumberStyles.Number, CultureInfo.InvariantCulture, out var value))
        {
            error = $"'{raw}' is not a valid amount.";
            return false;
        }

        try
        {
            paisa = checked((long)Math.Round(value * 100m, MidpointRounding.AwayFromZero));
        }
        catch (OverflowException)
        {
            error = $"'{raw}' is too large.";
            return false;
        }
        return true;
    }

    /// <summary>A percentage ("13", "13%", "13.0") to basis points (1300).</summary>
    private static bool TryPercent(string? raw, out int bps, out string? error)
    {
        bps = 0;
        error = null;
        if (string.IsNullOrWhiteSpace(raw)) return true;

        var cleaned = CleanNumber(raw.Replace("%", string.Empty, StringComparison.Ordinal));
        if (cleaned.Length == 0 || !decimal.TryParse(
                cleaned, NumberStyles.Number, CultureInfo.InvariantCulture, out var value))
        {
            error = $"'{raw}' is not a valid tax rate (use a percentage such as 13 or 13%).";
            return false;
        }

        try
        {
            bps = checked((int)Math.Round(value * 100m, MidpointRounding.AwayFromZero));
        }
        catch (OverflowException)
        {
            error = $"'{raw}' is out of range.";
            return false;
        }
        return true;
    }

    private static bool TryQuantity(string? raw, out decimal value, out string? error)
    {
        value = 0;
        error = null;
        if (string.IsNullOrWhiteSpace(raw)) return true;

        var cleaned = CleanNumber(raw);
        if (cleaned.Length == 0 || !decimal.TryParse(
                cleaned, NumberStyles.Number, CultureInfo.InvariantCulture, out value))
        {
            error = $"'{raw}' is not a valid quantity.";
            return false;
        }
        return true;
    }

    /// <summary>
    /// Strips currency markers, percent signs, thousands separators and spaces,
    /// keeping the digits, decimal point and sign. Everything else is left in
    /// place on purpose: "12x" must FAIL to parse rather than silently import
    /// as 12, so a typo can never become money.
    /// </summary>
    private static string CleanNumber(string raw)
    {
        var text = raw.Trim();
        foreach (var token in CurrencyTokens)
            text = text.Replace(token, string.Empty, StringComparison.OrdinalIgnoreCase);

        return text.Replace(",", string.Empty, StringComparison.Ordinal)
            .Replace(" ", string.Empty, StringComparison.Ordinal);
    }

    /// <summary>Currency markers a Nepali spreadsheet may prefix an amount with.</summary>
    private static readonly string[] CurrencyTokens = ["Rs.", "Rs", "NPR", "रु", "₹", "%"];

    // --- Plans ---

    /// <summary>One product row that passed validation, with what to do with it.</summary>
    private sealed record ProductPlan(
        CreateProductRequest Request,
        string? CategoryName,
        bool IsDuplicate);

    private sealed record CustomerPlan(CreateCustomerRequest Request, bool IsDuplicate);

    private sealed record ProductAnalysis(
        ImportPreviewDto Preview,
        IReadOnlyList<ProductPlan> Plans,
        IReadOnlyCollection<string> NewCategories);

    private sealed record CustomerAnalysis(
        ImportPreviewDto Preview,
        IReadOnlyList<CustomerPlan> Plans);
}
