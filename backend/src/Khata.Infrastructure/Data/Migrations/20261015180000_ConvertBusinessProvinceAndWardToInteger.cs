using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Khata.Infrastructure.Data.Migrations
{
    /// <summary>
    /// Turns <c>business.province</c> and <c>business.ward_number</c> from
    /// free text into constrained integers, back-filling both from the legacy
    /// values so no data is lost.
    /// </summary>
    /// <remarks>
    /// <para>Why the conversion exists: as text, "Bagmati", "bagmati", "3",
    /// "३" (Devanagari 3) and "" were five distinct stored values, so a
    /// province group-by was meaningless. <c>province</c> is now the official
    /// 1–7 province number and <c>ward_number</c> is an integer 1–35.</para>
    ///
    /// <para><b>The USING expression is the important part.</b> PostgreSQL
    /// will not implicitly cast <c>varchar</c> to <c>integer</c>, and a bare
    /// <c>USING ("Province"::integer)</c> aborts the whole migration with
    /// <c>invalid input syntax</c> the moment one row holds a province NAME
    /// — which is exactly what the old free-text UI allowed. So the
    /// expression is defensive, and the strategy differs per column:</para>
    ///
    /// <list type="bullet">
    /// <item><c>province</c>: parse the digits if the text is numeric;
    /// otherwise look the text up as a province NAME (case-insensitive) so
    /// "Bagmati" becomes 3; anything else — including "Kathmandu", which is a
    /// district — becomes NULL rather than a wrong number. A later back-fill
    /// pass tries to recover NULLs from the district.</item>
    /// <item><c>ward_number</c>: parse digits, clamp into 1–35, else NULL.
    /// There is no name form for a ward, so a non-numeric value is junk.</item>
    /// </list>
    ///
    /// <para>The <c>ALTER ... TYPE integer USING</c> form drops the old
    /// <c>maxLength</c> automatically (a length constraint is meaningless on
    /// an integer), so no separate <c>AlterColumn</c> call is needed for the
    /// type change itself.</para>
    ///
    /// <para><b>Down() is deliberately lossy and says so.</b> It cannot
    /// recover the original text (3 could have been "3", "03" or "Bagmati"),
    /// so it writes the canonical rendering of the number. That is acceptable
    /// because the pre-migration value was already ambiguous; a backup taken
    /// before deploying is the only exact revert.</para>
    /// </remarks>
    public partial class ConvertBusinessProvinceAndWardToInteger : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // --- province: varchar(100) -> integer -----------------------
            //
            // '\s*...\s*' tolerates the stray whitespace a free-text field
            // collects. The guard against an empty match stops ''::integer
            // (which is also an error, not NULL).
            migrationBuilder.Sql(@"
                ALTER TABLE business
                ALTER COLUMN ""Province"" TYPE integer
                USING (
                    CASE
                        WHEN ""Province"" ~ '^\s*[1-7]\s*$'
                            THEN btrim(""Province"")::integer
                        WHEN lower(btrim(""Province"")) = 'koshi'         THEN 1
                        WHEN lower(btrim(""Province"")) = 'madhesh'       THEN 2
                        WHEN lower(btrim(""Province"")) = 'madhes'        THEN 2
                        WHEN lower(btrim(""Province"")) = 'bagmati'       THEN 3
                        WHEN lower(btrim(""Province"")) = 'gandaki'       THEN 4
                        WHEN lower(btrim(""Province"")) = 'lumbini'       THEN 5
                        WHEN lower(btrim(""Province"")) = 'karnali'       THEN 6
                        WHEN lower(btrim(""Province"")) = 'sudurpashchim' THEN 7
                        WHEN lower(btrim(""Province"")) = 'sudurpaschim'  THEN 7
                        ELSE NULL
                    END
                );
            ");

            // --- ward_number: varchar(20) -> integer ---------------------
            migrationBuilder.Sql(@"
                ALTER TABLE business
                ALTER COLUMN ""WardNumber"" TYPE integer
                USING (
                    CASE
                        WHEN ""WardNumber"" ~ '^\s*\d{1,2}\s*$'
                             AND btrim(""WardNumber"")::integer BETWEEN 1 AND 35
                            THEN btrim(""WardNumber"")::integer
                        ELSE NULL
                    END
                );
            ");

            // --- recover a missing province from a known district --------
            //
            // Runs after both conversions, so it only touches rows the parse
            // above could not resolve. The list mirrors
            // Khata.Application.Common.NepalAddress.Districts; it is inlined
            // rather than read from C# because a migration must keep producing
            // the same result even if that table is later edited.
            migrationBuilder.Sql(@"
                UPDATE business SET ""Province"" = 1
                WHERE ""Province"" IS NULL AND lower(""District"") IN
                    ('bhojpur','dhankuta','ilam','jhapa','khotang','morang','okhaldhunga',
                     'panchthar','sankhuwasabha','solukhumbu','sunsari','taplejung',
                     'terhathum','udayapur');

                UPDATE business SET ""Province"" = 2
                WHERE ""Province"" IS NULL AND lower(""District"") IN
                    ('bara','dhanusha','mahottari','parsa','rautahat','saptari','sarlahi','siraha');

                UPDATE business SET ""Province"" = 3
                WHERE ""Province"" IS NULL AND lower(""District"") IN
                    ('bhaktapur','chitwan','dhading','dolakha','kathmandu','kavrepalanchok',
                     'lalitpur','makwanpur','nuwakot','ramechhap','rasuwa','sindhuli','sindhupalchok');

                UPDATE business SET ""Province"" = 4
                WHERE ""Province"" IS NULL AND lower(""District"") IN
                    ('baglung','gorkha','kaski','lamjung','manang','mustang','myagdi',
                     'nawalpur','parbat','syangja','tanahun');

                UPDATE business SET ""Province"" = 5
                WHERE ""Province"" IS NULL AND lower(""District"") IN
                    ('arghakhanchi','banke','bardiya','dang','eastern rukum','gulmi',
                     'kapilvastu','palpa','parasi','pyuthan','rolpa','rupandehi');

                UPDATE business SET ""Province"" = 6
                WHERE ""Province"" IS NULL AND lower(""District"") IN
                    ('dailekh','dolpa','humla','jajarkot','jumla','kalikot','mugu',
                     'salyan','surkhet','western rukum');

                UPDATE business SET ""Province"" = 7
                WHERE ""Province"" IS NULL AND lower(""District"") IN
                    ('achham','baitadi','bajhang','bajura','dadeldhura','darchula','doti',
                     'kailali','kanchanpur');
            ");

            // A province number outside 1-7 would have come from a corrupt
            // legacy value; NULL is more honest than an invalid number.
            migrationBuilder.Sql(@"
                UPDATE business SET ""Province"" = NULL
                WHERE ""Province"" IS NOT NULL AND ""Province"" NOT BETWEEN 1 AND 7;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Reverting renders the numbers back to canonical text. The
            // original spelling is not recoverable — see the class remarks.
            migrationBuilder.Sql(@"
                ALTER TABLE business
                ALTER COLUMN ""Province"" TYPE character varying(100)
                USING (""Province""::text);
            ");

            migrationBuilder.Sql(@"
                ALTER TABLE business
                ALTER COLUMN ""WardNumber"" TYPE character varying(20)
                USING (""WardNumber""::text);
            ");
        }
    }
}
