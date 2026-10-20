using System.Text;
using Khata.Application.Documents;
using Khata.Infrastructure.Documents;

namespace Khata.Tests.Unit;

/// <summary>
/// PDF generation correctness: the rendered bytes must be a well-formed PDF
/// with the document's content laid out by the template.
/// </summary>
public class DocumentPdfTests
{
    private readonly QuestPdfDocumentGenerator _generator = new();

    private static readonly BusinessLetterhead Business = new(
        "Himal Kirana Store", "Chabahil, Siphal", "Kathmandu", "Kathmandu",
        "+9779812345678", "shop@example.com", "123456789");

    private static readonly DocumentParty Customer = new(
        "Hari Bahadur", "+9779800000001", "Baneshwor, Kathmandu", "987654321");

    private static readonly IReadOnlyList<DocumentLine> Lines =
    [
        new("Basmati Rice 5kg", 2, 110000, 5000, 1300, 27950, 242950),
        new("Sunflower Oil 1L", 3, 32000, 0, 1300, 12480, 108480),
        new("Delivery charge", 1, 5000, 0, 0, 0, 5000),
    ];

    [Fact]
    public void GenerateInvoice_ProducesAWellFormedPdf()
    {
        var model = new InvoicePdfModel(
            Business, "INV-00007", "Draft", new DateOnly(2026, 10, 14), new DateOnly(2026, 11, 13),
            Customer, Lines, 326000, 5000, 40430, 356430,
            "Deliver before Friday.", "Payment due within 30 days.", "NPR");

        var bytes = _generator.GenerateInvoice(model);

        AssertWellFormedPdf(bytes);
    }

    [Fact]
    public void GenerateQuotation_ProducesAWellFormedPdf()
    {
        var model = new QuotationPdfModel(
            Business, "QT-00001", "Sent", new DateOnly(2026, 10, 14), new DateOnly(2026, 10, 28),
            Customer, Lines, 326000, 5000, 40430, 356430,
            null, "Prices valid for 14 days.", "NPR");

        var bytes = _generator.GenerateQuotation(model);

        AssertWellFormedPdf(bytes);
    }

    [Fact]
    public void GenerateInvoice_HandlesAWalkInWithNoCustomer()
    {
        var model = new InvoicePdfModel(
            Business, "INV-00008", "Draft", new DateOnly(2026, 10, 14), null,
            null, [Lines[0]], 110000, 0, 14300, 124300, null, null, "NPR");

        var bytes = _generator.GenerateInvoice(model);

        AssertWellFormedPdf(bytes);
    }

    [Fact]
    public void GenerateInvoice_HandlesManyLinesAcrossPages()
    {
        var manyLines = Enumerable.Range(1, 60)
            .Select(i => new DocumentLine($"Item number {i} with a fairly long description", i, 1500, 0, 1300, 195 * i, (1500 * i) + (195 * i)))
            .ToList();

        var model = new InvoicePdfModel(
            Business, "INV-00009", "Sent", new DateOnly(2026, 10, 14), null,
            Customer, manyLines, manyLines.Sum(l => l.LineTotal), 0, 0,
            manyLines.Sum(l => l.LineTotal), "Long invoice", null, "NPR");

        var bytes = _generator.GenerateInvoice(model);

        AssertWellFormedPdf(bytes);
        // Multi-page output is materially larger than the single-page case.
        Assert.True(bytes.Length > 3000, $"Expected a multi-page PDF, got {bytes.Length} bytes");
    }

    private static void AssertWellFormedPdf(byte[] bytes)
    {
        Assert.NotNull(bytes);
        Assert.True(bytes.Length > 1500, $"PDF suspiciously small: {bytes.Length} bytes");

        var head = Encoding.ASCII.GetString(bytes, 0, 5);
        Assert.Equal("%PDF-", head);

        // The trailer marker must be present (allow trailing whitespace/EOL).
        var tail = Encoding.ASCII.GetString(bytes, Math.Max(0, bytes.Length - 64), Math.Min(64, bytes.Length));
        Assert.Contains("%%EOF", tail);
    }
}
