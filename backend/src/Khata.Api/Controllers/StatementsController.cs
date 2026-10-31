namespace Khata.Api.Controllers;

using System.Globalization;
using System.Text;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Public customer statement links (shareable khata ledger).</summary>
public class StatementsController : ControllerBase
{
    private readonly IStatementService _statements;
    private readonly IConfiguration _config;

    public StatementsController(IStatementService statements, IConfiguration config)
    {
        _statements = statements;
        _config = config;
    }

    /// <summary>
    /// Mint a signed, expiring link to this customer's public ledger.
    /// The returned URL can be shared via WhatsApp, SMS, etc.
    /// </summary>
    [HttpPost("api/customers/{customerId:long}/statement-link")]
    [Authorize(Policy = Permissions.CustomersView)]
    [ProducesResponseType(typeof(StatementLinkResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<StatementLinkResponse>> MintLink(
        long customerId,
        [FromQuery] int ttlDays = 7)
    {
        // Bounded, not trusted. A caller-supplied int went straight into
        // TimeSpan.FromDays, so ttlDays=999999999 overflowed and produced a 500,
        // and a large-but-valid value minted a link that never expires — a
        // customer's whole ledger, public, forever. 90 days is the ceiling.
        // Negative values are allowed on purpose: they mint an already-expired
        // link, which is how a previously shared URL is retired.
        var days = Math.Clamp(ttlDays, -365, 90);

        var token = await _statements.MintTokenAsync(customerId, TimeSpan.FromDays(days));

        // A configured base wins, because behind a proxy the request's own host
        // is whatever the client sent. Blank-but-present counts as unset: an
        // empty value would otherwise mint a relative "/s/…" link that is
        // useless in the WhatsApp message it was made for.
        var configured = _config["StatementLink:BaseUrl"];
        var baseUrl = string.IsNullOrWhiteSpace(configured)
            ? $"{Request.Scheme}://{Request.Host}"
            : configured.TrimEnd('/');

        return Ok(new StatementLinkResponse(
            $"{baseUrl}/s/{token}",
            DateTimeOffset.UtcNow.AddDays(days)));
    }

    /// <summary>
    /// Render a public customer statement as HTML. Anonymous — anyone with the
    /// link can view it until it expires.
    /// </summary>
    [HttpGet("s/{token}")]
    [AllowAnonymous]
    [Produces("text/html")]
    public async Task<IActionResult> ShowStatement(
        string token,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        // This URL is a bearer token for a customer's whole ledger, and the
        // response is HTML — the one content type an intermediary is allowed to
        // cache by default. Without an explicit no-store, a shared proxy, a CDN
        // or the browser's back-forward cache can serve the page to the next
        // person on that device long after the link expired. The token is
        // unguessable but long-lived, so keep it out of indexes and archives as
        // well: a leaked URL must not become a search result.
        Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0";
        Response.Headers["Pragma"] = "no-cache";
        Response.Headers["X-Robots-Tag"] = "noindex, nofollow, noarchive, nosnippet";

        // Nothing on this page loads anything: the stylesheet is inline and
        // there is no script or image. Pinning it to exactly that removes the
        // whole class of injected-resource problems if the renderer ever gains
        // a field whose content reaches the markup.
        Response.Headers["Content-Security-Policy"] =
            "default-src 'none'; style-src 'unsafe-inline'; img-src data:; " +
            "base-uri 'none'; form-action 'none'; frame-ancestors 'none'";

        var stmt = await _statements.GetStatementAsync(token, page, pageSize);
        var html = RenderHtml(stmt);
        return Content(html, "text/html; charset=utf-8");
    }

    // ------------------------------------------------------------------
    // HTML renderer
    // ------------------------------------------------------------------

    private static string RenderHtml(PublicStatementDto stmt)
    {
        var sb = new StringBuilder();
        var l = stmt.Ledger;
        var s = l.Summary;

        sb.Append("<!DOCTYPE html><html lang=\"en\"><head>");
        sb.Append("<meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">");
        sb.Append("<title>").Append(Escape(stmt.BusinessName)).Append(" — ").Append(Escape(stmt.CustomerName)).Append("</title>");
        sb.Append("<style>");
        sb.Append(@"
            :root{--bg:#f8f9fa;--card:#fff;--text:#212529;--muted:#6c757d;--border:#dee2e6;--accent:#0d6efd;}
            *{box-sizing:border-box}
            body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;background:var(--bg);color:var(--text);margin:0;padding:1rem;line-height:1.5}
            .container{max-width:720px;margin:0 auto}
            .card{background:var(--card);border-radius:.5rem;box-shadow:0 1px 3px rgba(0,0,0,.08);padding:1.25rem;margin-bottom:1rem}
            h1{font-size:1.25rem;margin:0 0 .25rem}
            .muted{color:var(--muted);font-size:.875rem}
            .summary{display:grid;grid-template-columns:repeat(2,1fr);gap:1rem;margin-top:1rem}
            .summary div{background:#f1f3f5;border-radius:.375rem;padding:.75rem 1rem}
            .summary div span{display:block;font-size:.75rem;color:var(--muted);text-transform:uppercase;letter-spacing:.02em}
            .summary div strong{font-size:1.125rem}
            table{width:100%;border-collapse:collapse;margin-top:1rem;font-size:.875rem}
            th,td{padding:.6rem .5rem;text-align:left;border-bottom:1px solid var(--border)}
            th{color:var(--muted);font-weight:600;font-size:.75rem;text-transform:uppercase}
            td{white-space:nowrap}
            .num{text-align:right;font-variant-numeric:tabular-nums}
            .debit{color:#198754}
            .credit{color:#dc3545}
            .footer{text-align:center;color:var(--muted);font-size:.75rem;margin-top:1.5rem}
            @media(max-width:480px){.summary{grid-template-columns:1fr}table{font-size:.8rem}th,td{padding:.45rem .35rem}}
        ");
        sb.Append("</style></head><body><div class=\"container\">");

        // Header
        sb.Append("<div class=\"card\">");
        sb.Append("<h1>").Append(Escape(stmt.BusinessName)).Append("</h1>");
        if (!string.IsNullOrEmpty(stmt.BusinessPhone))
            sb.Append("<div class=\"muted\">").Append(Escape(stmt.BusinessPhone)).Append("</div>");
        sb.Append("<div class=\"muted\" style=\"margin-top:.5rem\">Ledger for <strong>").Append(Escape(stmt.CustomerName)).Append("</strong>");
        if (!string.IsNullOrEmpty(stmt.CustomerPhone))
            sb.Append(" &middot; ").Append(Escape(stmt.CustomerPhone));
        sb.Append("</div>");

        // Summary
        sb.Append("<div class=\"summary\">");
        sb.Append("<div><span>Opening balance</span><strong>").Append(Money(s.OpeningBalance)).Append("</strong></div>");
        sb.Append("<div><span>Closing balance</span><strong>").Append(Money(s.ClosingBalance)).Append("</strong></div>");
        sb.Append("<div><span>Total debit</span><strong>").Append(Money(s.TotalDebit)).Append("</strong></div>");
        sb.Append("<div><span>Total credit</span><strong>").Append(Money(s.TotalCredit)).Append("</strong></div>");
        sb.Append("</div></div>");

        // Transactions
        sb.Append("<div class=\"card\">");
        if (l.Data.Count == 0)
        {
            sb.Append("<p class=\"muted\">No transactions yet.</p>");
        }
        else
        {
            sb.Append("<table><thead><tr><th>Date</th><th>Description</th><th class=\"num\">Debit</th><th class=\"num\">Credit</th><th class=\"num\">Balance</th></tr></thead><tbody>");
            foreach (var t in l.Data)
            {
                var desc = t.Description ?? t.ReferenceType ?? "—";
                var debit = t.TransactionType == Domain.Enums.LedgerEntryType.Debit ? t.Amount : 0;
                var credit = t.TransactionType == Domain.Enums.LedgerEntryType.Credit ? t.Amount : 0;
                sb.Append("<tr><td>").Append(t.TransactionDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)).Append("</td>");
                sb.Append("<td>").Append(Escape(desc)).Append("</td>");
                sb.Append("<td class=\"num debit\">").Append(debit > 0 ? Money(debit) : "—").Append("</td>");
                sb.Append("<td class=\"num credit\">").Append(credit > 0 ? Money(credit) : "—").Append("</td>");
                sb.Append("<td class=\"num\">").Append(Money(t.BalanceAfter)).Append("</td></tr>");
            }
            sb.Append("</tbody></table>");

            // Pagination
            var p = l.Pagination;
            if (p.TotalPages > 1)
            {
                sb.Append("<div style=\"margin-top:1rem;text-align:center\">");
                if (p.HasPrev)
                    sb.Append("<a href=\"?page=").Append(p.Page - 1).Append("\" style=\"margin-right:1rem\">&larr; Previous</a>");
                sb.Append("<span class=\"muted\">Page ").Append(p.Page).Append(" of ").Append(p.TotalPages).Append("</span>");
                if (p.HasNext)
                    sb.Append("<a href=\"?page=").Append(p.Page + 1).Append("\" style=\"margin-left:1rem\">Next &rarr;</a>");
                sb.Append("</div>");
            }
        }
        sb.Append("</div>");

        sb.Append("<div class=\"footer\">Powered by Khata</div>");
        sb.Append("</div></body></html>");

        return sb.ToString();
    }

    private static string Money(long paisa)
        => (paisa / 100m).ToString("N2", CultureInfo.InvariantCulture);

    private static string Escape(string? text)
    {
        if (string.IsNullOrEmpty(text)) return string.Empty;
        return text
            .Replace("&", "&amp;")
            .Replace("<", "&lt;")
            .Replace(">", "&gt;")
            .Replace("\"", "&quot;");
    }
}

public record StatementLinkResponse(string Url, DateTimeOffset ExpiresAt);
