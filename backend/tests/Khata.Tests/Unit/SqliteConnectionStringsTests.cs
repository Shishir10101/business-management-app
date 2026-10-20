using Khata.Infrastructure.Data;
using Xunit;

namespace Khata.Tests.Unit;

/// <summary>
/// The in-memory vs file-backed decision that picks a connection lifetime.
/// </summary>
/// <remarks>
/// This is load-bearing. File-backed SQLite must use one connection per
/// request: a single shared connection caused real 500s under concurrent load
/// ("database is locked", "unable to delete/modify user-function due to active
/// statements"). In-memory SQLite must keep the single shared connection,
/// because the database dies with its last connection — and that is what the
/// 350-test integration suite runs on. Misclassifying either way breaks
/// something silently, so the rules are pinned here.
/// </remarks>
public class SqliteConnectionStringsTests
{
    [Theory]
    [InlineData("DataSource=:memory:")]
    [InlineData("DataSource=file::memory:?cache=shared")]
    [InlineData("DataSource=:MEMORY:")]
    [InlineData("Mode=Memory;DataSource=:memory:")]
    [InlineData("DataSource=:memory:;Cache=Shared")]
    [InlineData("Filename=:memory:")]
    [InlineData("Data Source=:memory:")]
    public void InMemoryForms_AreDetected(string connectionString)
        => Assert.True(SqliteConnectionStrings.IsInMemory(connectionString));

    [Theory]
    [InlineData("DataSource=khata_demo.db")]
    [InlineData("DataSource=khata_demo.db;Cache=Shared")]
    [InlineData("DataSource=C:\\data\\khata.db")]
    [InlineData("DataSource=/var/lib/khata.db")]
    [InlineData("Filename=khata_demo.db")]
    [InlineData("Mode=ReadWriteCreate;DataSource=khata.db")]
    [InlineData("DataSource=memory.db")]
    [InlineData("DataSource=my-memory.db")]
    [InlineData("Host=localhost;Port=5432;Database=khata_dev;Username=postgres")]
    [InlineData("")]
    [InlineData(null)]
    public void FileBackedAndOtherProviders_AreNotInMemory(string? connectionString)
        => Assert.False(SqliteConnectionStrings.IsInMemory(connectionString));

    [Fact]
    public void QuotedMemoryPath_IsDetected()
        => Assert.True(SqliteConnectionStrings.IsInMemory("DataSource=\":memory:\""));
}
