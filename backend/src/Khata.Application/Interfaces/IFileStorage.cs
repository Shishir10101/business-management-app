namespace Khata.Application.Interfaces;

/// <summary>A stored file's location and metadata.</summary>
public record StoredFile(string Key, string ContentType, long Length);

/// <summary>
/// Binary file storage for generated documents. The default implementation
/// writes to the local filesystem; an S3-compatible implementation can be
/// swapped in without touching the invoice service.
/// </summary>
public interface IFileStorage
{
    Task<StoredFile> SaveAsync(
        string key, byte[] content, string contentType, CancellationToken cancellationToken = default);

    Task<byte[]?> ReadAsync(string key, CancellationToken cancellationToken = default);

    Task DeleteAsync(string key, CancellationToken cancellationToken = default);
}
