namespace Khata.Api.Middleware;

using Khata.Domain.Exceptions;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

/// <summary>
/// Maps domain exceptions to RFC 7807 ProblemDetails responses so controllers
/// can throw domain exceptions instead of hand-rolling error responses.
/// </summary>
internal sealed class GlobalExceptionHandler : IExceptionHandler
{
    private readonly IProblemDetailsService _problemDetailsService;
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(
        IProblemDetailsService problemDetailsService,
        ILogger<GlobalExceptionHandler> logger)
    {
        _problemDetailsService = problemDetailsService;
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var (status, title) = MapException(exception);

        if (status >= StatusCodes.Status500InternalServerError)
        {
            _logger.LogError(exception, "Unhandled exception: {Message}", exception.Message);
        }
        else
        {
            _logger.LogInformation(
                "Handled {ExceptionType}: {Message}", exception.GetType().Name, exception.Message);
        }

        httpContext.Response.StatusCode = status;

        var problemDetails = new ProblemDetails
        {
            Status = status,
            Title = title,
            // 500s stay opaque — never leak internal details to clients.
            Detail = status >= StatusCodes.Status500InternalServerError
                ? "An unexpected error occurred. Please try again later."
                : exception.Message,
            Type = $"https://httpstatuses.io/{status}",
        };

        if (exception is Khata.Domain.Exceptions.ValidationException validationEx)
            problemDetails.Extensions["errors"] = validationEx.Errors;

        if (exception is FluentValidation.ValidationException fluentEx)
            problemDetails.Extensions["errors"] = fluentEx.Errors
                .GroupBy(e => e.PropertyName)
                .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray());

        return await _problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            Exception = exception,
            ProblemDetails = problemDetails,
        });
    }

    private static (int status, string title) MapException(Exception exception) => exception switch
    {
        Khata.Domain.Exceptions.ValidationException => (StatusCodes.Status400BadRequest, "Validation failed"),
        FluentValidation.ValidationException => (StatusCodes.Status400BadRequest, "Validation failed"),
        UnauthorizedException => (StatusCodes.Status401Unauthorized, "Unauthorized"),
        ForbiddenException => (StatusCodes.Status403Forbidden, "Forbidden"),
        NotFoundException => (StatusCodes.Status404NotFound, "Not found"),
        ConflictException => (StatusCodes.Status409Conflict, "Conflict"),
        BusinessRuleException => (StatusCodes.Status422UnprocessableEntity, "Business rule violated"),
        Microsoft.EntityFrameworkCore.DbUpdateConcurrencyException =>
            (StatusCodes.Status409Conflict, "Concurrency conflict"),
        _ => (StatusCodes.Status500InternalServerError, "Server error"),
    };
}
