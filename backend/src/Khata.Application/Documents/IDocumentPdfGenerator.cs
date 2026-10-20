namespace Khata.Application.Documents;

/// <summary>
/// Renders invoices and quotations to PDF bytes. Implemented with QuestPDF;
/// the abstraction keeps the service layer free of any PDF dependency.
/// </summary>
public interface IDocumentPdfGenerator
{
    byte[] GenerateInvoice(InvoicePdfModel model);

    byte[] GenerateQuotation(QuotationPdfModel model);
}
