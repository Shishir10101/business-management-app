namespace Khata.Infrastructure.Documents;

using System.Globalization;
using Khata.Application.Documents;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

/// <summary>
/// QuestPDF implementation of the invoice/quotation template: business
/// letterhead, party block, line-item table, totals and notes/terms.
/// </summary>
public class QuestPdfDocumentGenerator : IDocumentPdfGenerator
{
    private static readonly string Accent = "#1B5E20"; // deep green (khata brand-ish)

    static QuestPdfDocumentGenerator()
    {
        // QuestPDF Community licence (free for organisations under the revenue cap).
        QuestPDF.Settings.License = LicenseType.Community;
    }

    public byte[] GenerateInvoice(InvoicePdfModel model) => Build(
        title: "INVOICE",
        number: model.InvoiceNumber,
        status: model.Status,
        business: model.Business,
        party: model.Customer,
        partyLabel: "Billed to",
        primaryDateLabel: "Invoice date",
        primaryDate: model.IssueDate,
        secondaryDateLabel: "Due date",
        secondaryDate: model.DueDate,
        lines: model.Lines,
        subtotal: model.Subtotal,
        discount: model.DiscountAmount,
        tax: model.TaxAmount,
        total: model.TotalAmount,
        notes: model.Notes,
        terms: model.Terms,
        currency: model.Currency);

    public byte[] GenerateQuotation(QuotationPdfModel model) => Build(
        title: "QUOTATION",
        number: model.QuoteNumber,
        status: model.Status,
        business: model.Business,
        party: model.Customer,
        partyLabel: "Quoted to",
        primaryDateLabel: "Date",
        primaryDate: model.IssueDate,
        secondaryDateLabel: "Valid until",
        secondaryDate: model.ValidUntil,
        lines: model.Lines,
        subtotal: model.Subtotal,
        discount: model.DiscountAmount,
        tax: model.TaxAmount,
        total: model.TotalAmount,
        notes: model.Notes,
        terms: model.Terms,
        currency: model.Currency);

    private static byte[] Build(
        string title,
        string number,
        string status,
        BusinessLetterhead business,
        DocumentParty? party,
        string partyLabel,
        string primaryDateLabel,
        DateOnly primaryDate,
        string secondaryDateLabel,
        DateOnly? secondaryDate,
        IReadOnlyList<DocumentLine> lines,
        long subtotal,
        long discount,
        long tax,
        long total,
        string? notes,
        string? terms,
        string currency)
    {
        return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(32);
                page.DefaultTextStyle(x => x.FontSize(9.5f).FontColor(Colors.Grey.Darken3));

                page.Header().Element(header => ComposeHeader(header, title, number, status, business));
                page.Content().Element(content =>
                    ComposeContent(content, party, partyLabel, primaryDateLabel, primaryDate,
                        secondaryDateLabel, secondaryDate, lines, subtotal, discount, tax, total,
                        notes, terms, currency));
                page.Footer().Element(ComposeFooter);
            });
        }).GeneratePdf();
    }

    private static void ComposeHeader(
        IContainer container, string title, string number, string status, BusinessLetterhead business)
    {
        container.Column(column =>
        {
            column.Item().Row(row =>
            {
                row.RelativeItem().Column(left =>
                {
                    left.Item().Text(business.Name).FontSize(17).SemiBold().FontColor(Accent);
                    if (!string.IsNullOrWhiteSpace(business.AddressLine))
                        left.Item().Text(business.AddressLine!);
                    var locality = string.Join(", ",
                        new[] { business.City, business.District }.Where(x => !string.IsNullOrWhiteSpace(x)));
                    if (locality.Length > 0)
                        left.Item().Text(locality);
                    if (!string.IsNullOrWhiteSpace(business.PhoneNumber))
                        left.Item().Text($"Phone: {business.PhoneNumber}");
                    if (!string.IsNullOrWhiteSpace(business.Email))
                        left.Item().Text(business.Email!);
                    if (!string.IsNullOrWhiteSpace(business.PanNumber))
                        left.Item().Text($"PAN: {business.PanNumber}");
                });

                row.ConstantItem(190).Column(right =>
                {
                    right.Item().AlignRight().Text(title).FontSize(20).Bold().FontColor(Accent);
                    right.Item().AlignRight().Text(number).FontSize(11).SemiBold();
                    right.Item().AlignRight().PaddingTop(2).Text($"Status: {status}").FontSize(9);
                });
            });

            column.Item().PaddingVertical(10).LineHorizontal(1.2f).LineColor(Accent);
        });
    }

    private static void ComposeContent(
        IContainer container,
        DocumentParty? party,
        string partyLabel,
        string primaryDateLabel,
        DateOnly primaryDate,
        string secondaryDateLabel,
        DateOnly? secondaryDate,
        IReadOnlyList<DocumentLine> lines,
        long subtotal,
        long discount,
        long tax,
        long total,
        string? notes,
        string? terms,
        string currency)
    {
        container.Column(column =>
        {
            // --- party + dates ---
            column.Item().PaddingBottom(12).Row(row =>
            {
                row.RelativeItem().Column(left =>
                {
                    left.Item().Text(partyLabel).FontSize(8).SemiBold().FontColor(Colors.Grey.Darken1);
                    left.Item().PaddingTop(2).Text(party?.Name ?? "Walk-in customer").SemiBold();
                    if (!string.IsNullOrWhiteSpace(party?.AddressLine))
                        left.Item().Text(party!.AddressLine!);
                    if (!string.IsNullOrWhiteSpace(party?.PhoneNumber))
                        left.Item().Text($"Phone: {party!.PhoneNumber}");
                    if (!string.IsNullOrWhiteSpace(party?.PanNumber))
                        left.Item().Text($"PAN: {party!.PanNumber}");
                });

                row.ConstantItem(190).Column(right =>
                {
                    right.Item().Row(r =>
                    {
                        r.RelativeItem().Text(primaryDateLabel).FontColor(Colors.Grey.Darken1);
                        r.ConstantItem(90).AlignRight().Text(Format(primaryDate)).SemiBold();
                    });
                    if (secondaryDate is { } second)
                    {
                        right.Item().PaddingTop(2).Row(r =>
                        {
                            r.RelativeItem().Text(secondaryDateLabel).FontColor(Colors.Grey.Darken1);
                            r.ConstantItem(90).AlignRight().Text(Format(second)).SemiBold();
                        });
                    }
                });
            });

            // --- items ---
            column.Item().Table(table =>
            {
                table.ColumnsDefinition(columns =>
                {
                    columns.ConstantColumn(22);
                    columns.RelativeColumn(4);
                    columns.RelativeColumn(1.1f);
                    columns.RelativeColumn(1.5f);
                    columns.RelativeColumn(1.2f);
                    columns.RelativeColumn(1.2f);
                    columns.RelativeColumn(1.7f);
                });

                table.Header(header =>
                {
                    HeaderCell(header.Cell()).AlignRight().Text("#");
                    HeaderCell(header.Cell()).Text("Description");
                    HeaderCell(header.Cell()).AlignRight().Text("Qty");
                    HeaderCell(header.Cell()).AlignRight().Text("Rate");
                    HeaderCell(header.Cell()).AlignRight().Text("Discount");
                    HeaderCell(header.Cell()).AlignRight().Text("Tax");
                    HeaderCell(header.Cell()).AlignRight().Text("Amount");
                });

                var index = 0;
                foreach (var line in lines)
                {
                    index++;
                    BodyCell(table.Cell()).Text(index.ToString(CultureInfo.InvariantCulture));
                    BodyCell(table.Cell()).Text(line.Description);
                    BodyCell(table.Cell()).AlignRight().Text(FormatQuantity(line.Quantity));
                    BodyCell(table.Cell()).AlignRight().Text(Money(line.UnitPrice, currency));
                    BodyCell(table.Cell()).AlignRight().Text(Money(line.DiscountAmount, currency));
                    BodyCell(table.Cell()).AlignRight().Text(Money(line.TaxAmount, currency));
                    BodyCell(table.Cell()).AlignRight().Text(Money(line.LineTotal, currency)).SemiBold();
                }
            });

            // --- totals ---
            column.Item().PaddingTop(10).Row(row =>
            {
                row.RelativeItem();
                row.ConstantItem(230).Column(totals =>
                {
                    TotalRow(totals, "Subtotal", Money(subtotal, currency));
                    if (discount != 0)
                        TotalRow(totals, "Discount", "-" + Money(discount, currency));
                    if (tax != 0)
                        TotalRow(totals, "Tax", Money(tax, currency));
                    totals.Item().PaddingTop(4).LineHorizontal(0.8f).LineColor(Colors.Grey.Lighten1);
                    totals.Item().PaddingTop(4).Row(r =>
                    {
                        r.RelativeItem().Text("Total").FontSize(12).Bold().FontColor(Accent);
                        r.ConstantItem(110).AlignRight().Text(Money(total, currency))
                            .FontSize(12).Bold().FontColor(Accent);
                    });
                });
            });

            // --- notes / terms ---
            if (!string.IsNullOrWhiteSpace(notes))
                column.Item().PaddingTop(18).Column(c =>
                {
                    c.Item().Text("Notes").FontSize(8).SemiBold().FontColor(Colors.Grey.Darken1);
                    c.Item().PaddingTop(2).Text(notes!);
                });

            if (!string.IsNullOrWhiteSpace(terms))
                column.Item().PaddingTop(10).Column(c =>
                {
                    c.Item().Text("Terms & conditions").FontSize(8).SemiBold().FontColor(Colors.Grey.Darken1);
                    c.Item().PaddingTop(2).Text(terms!);
                });
        });
    }

    private static void ComposeFooter(IContainer container)
    {
        container.Column(column =>
        {
            column.Item().PaddingTop(6).LineHorizontal(0.8f).LineColor(Colors.Grey.Lighten1);
            column.Item().PaddingTop(4).Row(row =>
            {
                row.RelativeItem().Text("Thank you for your business.")
                    .FontSize(8).FontColor(Colors.Grey.Darken1);
                row.ConstantItem(120).AlignRight().Text(text =>
                {
                    text.DefaultTextStyle(x => x.FontSize(8).FontColor(Colors.Grey.Darken1));
                    text.Span("Page ");
                    text.CurrentPageNumber();
                    text.Span(" of ");
                    text.TotalPages();
                });
            });
        });
    }

    private static IContainer HeaderCell(IContainer container) => container
        .Background(Colors.Grey.Lighten3)
        .PaddingVertical(5)
        .PaddingHorizontal(4)
        .DefaultTextStyle(x => x.FontSize(8.5f).SemiBold());

    private static IContainer BodyCell(IContainer container) => container
        .BorderBottom(0.6f)
        .BorderColor(Colors.Grey.Lighten2)
        .PaddingVertical(5)
        .PaddingHorizontal(4);

    private static void TotalRow(ColumnDescriptor column, string label, string value)
    {
        column.Item().PaddingVertical(1).Row(row =>
        {
            row.RelativeItem().Text(label).FontColor(Colors.Grey.Darken1);
            row.ConstantItem(110).AlignRight().Text(value);
        });
    }

    private static string Money(long paisa, string currency)
    {
        var amount = paisa / 100m;
        var sign = amount < 0 ? "-" : string.Empty;
        return $"{sign}{currency} {Math.Abs(amount).ToString("N2", CultureInfo.InvariantCulture)}";
    }

    private static string FormatQuantity(decimal quantity) =>
        quantity == decimal.Truncate(quantity)
            ? decimal.Truncate(quantity).ToString(CultureInfo.InvariantCulture)
            : quantity.ToString("0.###", CultureInfo.InvariantCulture);

    private static string Format(DateOnly date) =>
        date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
}
