namespace Khata.Application.Common;

using System.Text;

/// <summary>One physical CSV record and the 1-based line number it came from.</summary>
public sealed record CsvRecord(int Number, IReadOnlyList<string> Fields);

/// <summary>
/// Minimal RFC 4180 CSV reader — enough for the files a shop actually exports
/// from Excel, Google Sheets or a phone: quoted fields, doubled quotes inside a
/// quoted field, embedded commas and newlines, CRLF / LF / CR line endings, and
/// a UTF-8 BOM.
/// </summary>
/// <remarks>
/// Blank lines are dropped, but the record counter still advances over them, so
/// a row number in an import error matches the line the user sees in a text
/// editor. An unterminated quote at end-of-file is treated as "the field runs
/// to the end" instead of throwing: a truncated paste should produce a readable
/// row error, not a 500.
/// </remarks>
public static class CsvReader
{
    public static IReadOnlyList<CsvRecord> Read(string? text)
    {
        var records = new List<CsvRecord>();
        if (string.IsNullOrEmpty(text)) return records;

        var input = text[0] == '\uFEFF' ? text[1..] : text;

        var fields = new List<string>();
        var field = new StringBuilder();
        var inQuotes = false;
        var touched = false;
        var recordNumber = 0;

        for (var i = 0; i < input.Length; i++)
        {
            var c = input[i];

            if (inQuotes)
            {
                if (c == '"')
                {
                    if (i + 1 < input.Length && input[i + 1] == '"')
                    {
                        field.Append('"');
                        i++;
                    }
                    else
                    {
                        inQuotes = false;
                    }
                }
                else
                {
                    field.Append(c);
                }
                touched = true;
                continue;
            }

            switch (c)
            {
                case '"':
                    inQuotes = true;
                    touched = true;
                    break;
                case ',':
                    fields.Add(field.ToString());
                    field.Clear();
                    touched = true;
                    break;
                case '\r':
                    if (i + 1 < input.Length && input[i + 1] == '\n') i++;
                    recordNumber++;
                    Flush();
                    break;
                case '\n':
                    recordNumber++;
                    Flush();
                    break;
                default:
                    field.Append(c);
                    touched = true;
                    break;
            }
        }

        if (touched || fields.Count > 0) recordNumber++;
        Flush();
        return records;

        void Flush()
        {
            fields.Add(field.ToString());
            field.Clear();

            // A line of only commas/whitespace is a blank line, not a row.
            if (fields.Any(f => !string.IsNullOrWhiteSpace(f)))
                records.Add(new CsvRecord(recordNumber, fields.ToArray()));

            fields.Clear();
            touched = false;
        }
    }
}

/// <summary>
/// A parsed CSV table with header lookup that ignores case, spaces, hyphens and
/// underscores — so "Cost Price", "cost_price" and "COSTPRICE" all resolve to
/// the same column, which is what real spreadsheet exports look like.
/// </summary>
public sealed class CsvTable
{
    private CsvTable(IReadOnlyList<string> headers, IReadOnlyList<CsvRecord> rows)
    {
        Headers = headers;
        Rows = rows;
    }

    /// <summary>Header cells of the first record, as written in the file.</summary>
    public IReadOnlyList<string> Headers { get; }

    /// <summary>Data records (the header record is not included).</summary>
    public IReadOnlyList<CsvRecord> Rows { get; }

    public static CsvTable Parse(string? text)
    {
        var records = CsvReader.Read(text);
        if (records.Count == 0) return new CsvTable([], []);

        var headers = records[0].Fields;
        return new CsvTable(headers, records.Skip(1).ToArray());
    }

    /// <summary>Index of the first header matching any alias, or null.</summary>
    public int? IndexOf(params string[] aliases)
    {
        var wanted = aliases.Select(Normalize).ToHashSet();
        for (var i = 0; i < Headers.Count; i++)
        {
            if (wanted.Contains(Normalize(Headers[i]))) return i;
        }
        return null;
    }

    /// <summary>The cell at <paramref name="column"/>, trimmed; null when absent or blank.</summary>
    public static string? Value(CsvRecord record, int? column)
    {
        if (column is not { } index || index < 0 || index >= record.Fields.Count) return null;
        var raw = record.Fields[index]?.Trim();
        return string.IsNullOrEmpty(raw) ? null : raw;
    }

    /// <summary>Lower-cased letters and digits only — the lookup key for a header.</summary>
    public static string Normalize(string header)
    {
        var builder = new StringBuilder(header.Length);
        foreach (var c in header)
        {
            if (char.IsLetterOrDigit(c)) builder.Append(char.ToLowerInvariant(c));
        }
        return builder.ToString();
    }
}
