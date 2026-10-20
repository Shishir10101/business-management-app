namespace Khata.Application.Common;

/// <summary>
/// Reference data for Nepal's administrative hierarchy, plus the range rules
/// that <c>Business.Province</c> and <c>Business.WardNumber</c> are validated
/// against.
/// </summary>
/// <remarks>
/// This exists because those two columns used to be free text. A client could
/// post <c>Province = "Bagmati"</c>, <c>"bagmati"</c>, <c>"3"</c>, <c>"३"</c>
/// and <c>""</c> and all five would be stored as distinct values, which makes
/// any group-by-province report meaningless. They are now nullable integers
/// with the range rules below, and the migration coerces the legacy text.
///
/// <para>Province numbering is the official 1–7 numbering used by the
/// Government of Nepal (1 = Koshi in the east, 7 = Sudurpashchim in the
/// west), NOT an alphabetical index — so the numbers are stable even if a
/// province is renamed, which has happened twice.</para>
///
/// <para>Ward count is capped at 35 because that is the most wards any single
/// Nepali municipality has; Kathmandu Metropolitan City has 32. A value above
/// that is a typo or a different field's data, so it is rejected rather than
/// silently accepted.</para>
/// </remarks>
public static class NepalAddress
{
    /// <summary>Lowest valid province number (Koshi, in the east).</summary>
    public const int MinProvince = 1;

    /// <summary>Highest valid province number (Sudurpashchim, in the west).</summary>
    public const int MaxProvince = 7;

    /// <summary>Highest ward number in any Nepali municipality (Kathmandu has 32).</summary>
    public const int MaxWardNumber = 35;

    /// <summary>
    /// Official English name for each province number.
    /// </summary>
    public static readonly IReadOnlyDictionary<int, string> ProvinceNames = new Dictionary<int, string>
    {
        [1] = "Koshi",
        [2] = "Madhesh",
        [3] = "Bagmati",
        [4] = "Gandaki",
        [5] = "Lumbini",
        [6] = "Karnali",
        [7] = "Sudurpashchim",
    };

    /// <summary>
    /// Every district, mapped to the province it belongs to. Used both to
    /// filter the client's district list when a province is chosen and — in
    /// the migration — to back-fill a province that is missing but whose
    /// district is known.
    /// </summary>
    /// <remarks>
    /// 77 districts: 14 in Koshi, 8 in Madhesh, 13 in Bagmati, 11 in Gandaki,
    /// 12 in Lumbini, 10 in Karnali, 9 in Sudurpashchim.
    /// </remarks>
    public static readonly IReadOnlyList<District> Districts =
    [
        // 1 — Koshi
        new("Bhojpur", 1), new("Dhankuta", 1), new("Ilam", 1), new("Jhapa", 1),
        new("Khotang", 1), new("Morang", 1), new("Okhaldhunga", 1), new("Panchthar", 1),
        new("Sankhuwasabha", 1), new("Solukhumbu", 1), new("Sunsari", 1), new("Taplejung", 1),
        new("Terhathum", 1), new("Udayapur", 1),

        // 2 — Madhesh
        new("Bara", 2), new("Dhanusha", 2), new("Mahottari", 2), new("Parsa", 2),
        new("Rautahat", 2), new("Saptari", 2), new("Sarlahi", 2), new("Siraha", 2),

        // 3 — Bagmati
        new("Bhaktapur", 3), new("Chitwan", 3), new("Dhading", 3), new("Dolakha", 3),
        new("Kathmandu", 3), new("Kavrepalanchok", 3), new("Lalitpur", 3), new("Makwanpur", 3),
        new("Nuwakot", 3), new("Ramechhap", 3), new("Rasuwa", 3), new("Sindhuli", 3),
        new("Sindhupalchok", 3),

        // 4 — Gandaki
        new("Baglung", 4), new("Gorkha", 4), new("Kaski", 4), new("Lamjung", 4),
        new("Manang", 4), new("Mustang", 4), new("Myagdi", 4), new("Nawalpur", 4),
        new("Parbat", 4), new("Syangja", 4), new("Tanahun", 4),

        // 5 — Lumbini
        new("Arghakhanchi", 5), new("Banke", 5), new("Bardiya", 5), new("Dang", 5),
        new("Eastern Rukum", 5), new("Gulmi", 5), new("Kapilvastu", 5), new("Palpa", 5),
        new("Parasi", 5), new("Pyuthan", 5), new("Rolpa", 5), new("Rupandehi", 5),

        // 6 — Karnali
        new("Dailekh", 6), new("Dolpa", 6), new("Humla", 6), new("Jajarkot", 6),
        new("Jumla", 6), new("Kalikot", 6), new("Mugu", 6), new("Salyan", 6),
        new("Surkhet", 6), new("Western Rukum", 6),

        // 7 — Sudurpashchim
        new("Achham", 7), new("Baitadi", 7), new("Bajhang", 7), new("Bajura", 7),
        new("Dadeldhura", 7), new("Darchula", 7), new("Doti", 7), new("Kailali", 7),
        new("Kanchanpur", 7),
    ];

    /// <summary>True when <paramref name="province"/> is a valid province number.</summary>
    public static bool IsValidProvince(int? province) =>
        province is null or (>= MinProvince and <= MaxProvince);

    /// <summary>True when <paramref name="ward"/> is a valid ward number.</summary>
    public static bool IsValidWardNumber(int? ward) =>
        ward is null or (>= 1 and <= MaxWardNumber);

    /// <summary>
    /// Case-insensitive district lookup. Returns the province number, or null
    /// for an unknown district so callers can choose between rejecting and
    /// ignoring rather than being forced into an exception.
    /// </summary>
    public static int? ProvinceForDistrict(string? district)
    {
        if (string.IsNullOrWhiteSpace(district)) return null;
        var needle = district.Trim();
        foreach (var d in Districts)
        {
            if (string.Equals(d.Name, needle, StringComparison.OrdinalIgnoreCase))
                return d.Province;
        }
        return null;
    }

    /// <summary>A district and the province number it belongs to.</summary>
    public readonly record struct District(string Name, int Province);
}
