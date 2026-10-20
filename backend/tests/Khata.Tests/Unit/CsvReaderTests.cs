using Khata.Application.Common;
using Xunit;

namespace Khata.Tests.Unit;

/// <summary>
/// The CSV reader is the one piece of the importer that has to survive whatever
/// Excel actually writes: quoted fields, embedded commas and newlines, doubled
/// quotes, CRLF, a BOM, and trailing blank lines.
/// </summary>
public class CsvReaderTests
{
    [Fact]
    public void Read_ParsesSimpleRows()
    {
        var records = CsvReader.Read("a,b\n1,2\n3,4");

        Assert.Equal(3, records.Count);
        Assert.Equal(new[] { "a", "b" }, records[0].Fields);
        Assert.Equal(new[] { "3", "4" }, records[2].Fields);
        Assert.Equal(3, records[2].Number);
    }

    [Fact]
    public void Read_HandlesQuotedCommasAndEscapedQuotes()
    {
        var records = CsvReader.Read("name,note\n\"Rice, 5kg\",\"He said \"\"hi\"\"\"\n");

        Assert.Equal(2, records.Count);
        Assert.Equal("Rice, 5kg", records[1].Fields[0]);
        Assert.Equal("He said \"hi\"", records[1].Fields[1]);
    }

    [Fact]
    public void Read_KeepsNewlinesInsideQuotedFields()
    {
        var records = CsvReader.Read("name,address\nRam,\"Kathmandu\nNepal\"\nSita,Pokhara\n");

        Assert.Equal(3, records.Count);
        Assert.Equal("Kathmandu\nNepal", records[1].Fields[1]);
        Assert.Equal("Sita", records[2].Fields[0]);
    }

    [Fact]
    public void Read_HandlesCrlfAndBom()
    {
        var records = CsvReader.Read("\uFEFFname,price\r\nRice,100\r\n");

        Assert.Equal(2, records.Count);
        Assert.Equal("name", records[0].Fields[0]);
        Assert.Equal("Rice", records[1].Fields[0]);
    }

    [Fact]
    public void Read_SkipsBlankLines_ButKeepsLineNumbersTrue()
    {
        var records = CsvReader.Read("name\n\nRice\n\n");

        Assert.Equal(2, records.Count);
        // The blank line still occupies line 2, so "Rice" is line 3.
        Assert.Equal(3, records[1].Number);
    }

    [Fact]
    public void Read_TrailingNewline_DoesNotProducePhantomRow()
    {
        var records = CsvReader.Read("a,b\n1,2\n");

        Assert.Equal(2, records.Count);
    }

    [Fact]
    public void Read_EmptyText_ReturnsNothing()
    {
        Assert.Empty(CsvReader.Read(""));
        Assert.Empty(CsvReader.Read(null));
    }

    [Fact]
    public void Read_UnterminatedQuote_KeepsRemainderInsteadOfThrowing()
    {
        var records = CsvReader.Read("name,note\nRice,\"unterminated");

        Assert.Equal(2, records.Count);
        Assert.Equal("unterminated", records[1].Fields[1]);
    }

    [Fact]
    public void Table_MatchesHeadersIgnoringCaseSpacesAndUnderscores()
    {
        var table = CsvTable.Parse("Product Name,COST_PRICE,Opening Quantity\nRice,100,5\n");

        // Exact after normalization: "Product Name" is "productname", not "name".
        Assert.Equal(0, table.IndexOf("productname"));
        Assert.Equal(1, table.IndexOf("costprice"));
        Assert.Equal(2, table.IndexOf("openingquantity"));
        Assert.Null(table.IndexOf("sku"));

        // Aliases resolve in the order given, which is how the importer reads
        // a file whose headers were written by hand.
        Assert.Equal(0, table.IndexOf("name", "productname", "item"));
    }

    [Fact]
    public void Table_Value_TrimsAndTreatsBlankAsNull()
    {
        var table = CsvTable.Parse("name,sku\nRice,  \n");
        var row = table.Rows[0];

        Assert.Equal("Rice", CsvTable.Value(row, table.IndexOf("name")));
        Assert.Null(CsvTable.Value(row, table.IndexOf("sku")));
        Assert.Null(CsvTable.Value(row, 99));
    }

    [Fact]
    public void Table_EmptyText_HasNoHeadersAndNoRows()
    {
        var table = CsvTable.Parse("");

        Assert.Empty(table.Headers);
        Assert.Empty(table.Rows);
    }
}
