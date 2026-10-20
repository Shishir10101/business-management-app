namespace Khata.Admin.Services;

/// <summary>
/// Raised when the admin API returns a non-success status. <see cref="IsUnauthorized"/>
/// lets the UI send the operator back to the login page instead of showing a
/// raw error, which is the only correct response to an expired token.
/// </summary>
public class AdminApiException : Exception
{
    public AdminApiException(int statusCode, string message) : base(message)
    {
        StatusCode = statusCode;
    }

    public int StatusCode { get; }

    public bool IsUnauthorized => StatusCode == StatusCodes.Status401Unauthorized;

    public bool IsForbidden => StatusCode == StatusCodes.Status403Forbidden;

    public bool IsNotFound => StatusCode == StatusCodes.Status404NotFound;
}
