namespace Khata.Domain.Exceptions;

public class KhataException : Exception
{
    public string Code { get; }

    public KhataException(string code, string message) : base(message)
    {
        Code = code;
    }

    public KhataException(string code, string message, Exception innerException)
        : base(message, innerException)
    {
        Code = code;
    }
}

public class NotFoundException : KhataException
{
    public NotFoundException(string entityName, object key)
        : base("not_found", $"{entityName} with key '{key}' was not found.")
    {
    }
}

public class ValidationException : KhataException
{
    public IDictionary<string, string[]> Errors { get; }

    public ValidationException(IDictionary<string, string[]> errors)
        : base("validation", "One or more validation errors occurred.")
    {
        Errors = errors;
    }
}

public class BusinessRuleException : KhataException
{
    public BusinessRuleException(string code, string message)
        : base(code, message)
    {
    }
}

public class InsufficientStockException : BusinessRuleException
{
    public string ProductName { get; }
    public decimal Available { get; }
    public decimal Requested { get; }

    public InsufficientStockException(string productName, decimal available, decimal requested)
        : base("insufficient_stock",
            $"Product '{productName}' has only {available} units in stock; sale requests {requested}.")
    {
        ProductName = productName;
        Available = available;
        Requested = requested;
    }
}

public class DuplicateInvoiceException : BusinessRuleException
{
    public DuplicateInvoiceException(string invoiceNumber)
        : base("duplicate_invoice",
            $"Invoice number '{invoiceNumber}' already exists for this business.")
    {
    }
}

public class UnauthorizedException : KhataException
{
    public UnauthorizedException(string message = "You are not authorized to perform this action.")
        : base("unauthorized", message)
    {
    }
}

public class ForbiddenException : KhataException
{
    public ForbiddenException(string message = "You do not have permission to perform this action.")
        : base("forbidden", message)
    {
    }
}

public class ConflictException : KhataException
{
    public ConflictException(string message)
        : base("conflict", message)
    {
    }
}
