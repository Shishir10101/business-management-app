namespace Khata.Infrastructure.Storage;

using Khata.Application.Interfaces;
using Microsoft.Extensions.Configuration;

/// <summary>
/// Filesystem-backed <see cref="IFileStorage"/> (the default). Keys are relative
/// paths under a configurable root (<c>FileStorage:RootPath</c>, defaulting to
/// a <c>storage</c> folder beside the app). An S3-compatible implementation can
/// replace this without touching the invoice service.
/// </summary>
public class LocalFileStorage : IFileStorage
{
    private readonly string _root;

    public LocalFileStorage(IConfiguration configuration)
    {
        var configured = configuration["FileStorage:RootPath"];
        _root = string.IsNullOrWhiteSpace(configured)
            ? Path.Combine(AppContext.BaseDirectory, "storage")
            : configured;

        Directory.CreateDirectory(_root);
    }

    public async Task<StoredFile> SaveAsync(
        string key, byte[] content, string contentType, CancellationToken cancellationToken = default)
    {
        var path = Resolve(key);
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        await File.WriteAllBytesAsync(path, content, cancellationToken);

        return new StoredFile(key, contentType, content.LongLength);
    }

    public async Task<byte[]?> ReadAsync(string key, CancellationToken cancellationToken = default)
    {
        var path = Resolve(key);
        return File.Exists(path)
            ? await File.ReadAllBytesAsync(path, cancellationToken)
            : null;
    }

    public Task DeleteAsync(string key, CancellationToken cancellationToken = default)
    {
        var path = Resolve(key);
        if (File.Exists(path))
            File.Delete(path);

        return Task.CompletedTask;
    }

    /// <summary>
    /// Maps a storage key to an absolute path, rejecting any key that would
    /// escape the storage root.
    /// </summary>
    private string Resolve(string key)
    {
        var relative = key.Replace('\\', '/').TrimStart('/');
        var root = Path.GetFullPath(_root);
        var full = Path.GetFullPath(Path.Combine(root, relative));

        // Compare against the root *plus its separator*. A bare StartsWith(root)
        // also accepts a sibling directory that merely shares the prefix —
        // "…/storage-evil" starts with "…/storage" — so "../storage-evil/x"
        // would have escaped the sandbox.
        var rootWithSeparator = root.EndsWith(Path.DirectorySeparatorChar)
            ? root
            : root + Path.DirectorySeparatorChar;

        if (!full.StartsWith(rootWithSeparator, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException($"Storage key '{key}' escapes the storage root.");

        return full;
    }
}
