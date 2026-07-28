using Hustle.Api.Contracts;
using Hustle.Api.Data;
using Hustle.Api.Models;
using Hustle.Api.Services;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace Hustle.Api.Tests;

public sealed class SignalIngestionServiceTests : IAsyncLifetime
{
    private readonly SqliteConnection _connection = new("Data Source=:memory:");
    private FintechDbContext _db = null!;
    private SignalIngestionService _service = null!;
    private Asset _asset = null!;

    public async Task InitializeAsync()
    {
        await _connection.OpenAsync();
        var options = new DbContextOptionsBuilder<FintechDbContext>()
            .UseSqlite(_connection)
            .Options;
        _db = new FintechDbContext(options);
        await _db.Database.EnsureCreatedAsync();

        _asset = new Asset { Id = Guid.NewGuid(), Symbol = "BTCUSDT", Exchange = "BINANCE" };
        _db.Assets.Add(_asset);
        await _db.SaveChangesAsync();
        _service = new SignalIngestionService(_db);
    }

    public async Task DisposeAsync()
    {
        await _db.DisposeAsync();
        await _connection.DisposeAsync();
    }

    [Fact]
    public async Task IngestAsync_PersistsSignalAndReturnsNoMatches_WhenThereAreNoRules()
    {
        var response = await _service.IngestAsync(CreateRequest(), CancellationToken.None);

        Assert.False(response.IsDuplicate);
        Assert.Equal(0, response.MatchedAlerts);
        var signal = await _db.MarketSignals.SingleAsync();
        Assert.Equal(response.SignalId, signal.Id);
        Assert.Equal("SAFE_BUY", signal.Action);
    }

    [Fact]
    public async Task IngestAsync_ReturnsExistingSignal_WhenSourceEventIsDuplicate()
    {
        var request = CreateRequest();
        var first = await _service.IngestAsync(request, CancellationToken.None);

        var duplicate = await _service.IngestAsync(request, CancellationToken.None);

        Assert.True(duplicate.IsDuplicate);
        Assert.Equal(first.SignalId, duplicate.SignalId);
        Assert.Equal(0, duplicate.MatchedAlerts);
        Assert.Equal(1, await _db.MarketSignals.CountAsync());
    }

    [Fact]
    public async Task IngestAsync_CreatesDeliveryAndOutbox_ForMatchingRule()
    {
        var rule = CreateRule();
        _db.AlertRules.Add(rule);
        await _db.SaveChangesAsync();

        var response = await _service.IngestAsync(CreateRequest(), CancellationToken.None);

        Assert.Equal(1, response.MatchedAlerts);
        var delivery = await _db.AlertDeliveries.SingleAsync();
        var outbox = await _db.NotificationOutbox.SingleAsync();
        Assert.Equal(rule.Id, delivery.AlertRuleId);
        Assert.Equal(delivery.Id, outbox.AlertDeliveryId);
        Assert.NotNull((await _db.AlertRules.SingleAsync()).LastTriggeredAt);
    }

    [Fact]
    public async Task IngestAsync_DoesNotMatch_InactiveExpiredLowConfidenceOrCooldownRules()
    {
        var now = DateTimeOffset.UtcNow;
        _db.AlertRules.AddRange(
            CreateRule(isActive: false),
            CreateRule(expiresAt: now.AddMinutes(-1)),
            CreateRule(minConfidence: 0.91m),
            CreateRule(lastTriggeredAt: now.AddMinutes(-5), cooldownMinutes: 60),
            CreateRule(timeframe: "4h"));
        await _db.SaveChangesAsync();

        var response = await _service.IngestAsync(CreateRequest(), CancellationToken.None);

        Assert.Equal(0, response.MatchedAlerts);
        Assert.Empty(await _db.AlertDeliveries.ToListAsync());
        Assert.Empty(await _db.NotificationOutbox.ToListAsync());
    }

    [Fact]
    public async Task IngestAsync_RejectsUnknownAction()
    {
        var request = CreateRequest() with { Action = "BUY_NOW" };

        var error = await Assert.ThrowsAsync<ArgumentException>(
            () => _service.IngestAsync(request, CancellationToken.None));

        Assert.Contains("SAFE_BUY", error.Message);
        Assert.Empty(await _db.MarketSignals.ToListAsync());
    }

    private IngestSignalRequest CreateRequest() => new(
        "hustle-analytics", "BINANCE:BTCUSDT:1h:123", "btcusdt", "binance", "1h",
        "safe_buy", 0.80m, 65000m, DateTimeOffset.UtcNow,
        ["test reason"], new Dictionary<string, object> { ["rsi_14"] = 25.0 });

    private AlertRule CreateRule(
        bool isActive = true,
        decimal minConfidence = 0.60m,
        string? timeframe = "1h",
        DateTimeOffset? expiresAt = null,
        DateTimeOffset? lastTriggeredAt = null,
        int cooldownMinutes = 60) => new()
    {
        Id = Guid.NewGuid(),
        UserId = Guid.NewGuid(),
        AssetId = _asset.Id,
        ExpectedAction = "SAFE_BUY",
        Timeframe = timeframe,
        MinConfidence = minConfidence,
        CooldownMinutes = cooldownMinutes,
        IsActive = isActive,
        ExpiresAt = expiresAt,
        LastTriggeredAt = lastTriggeredAt
    };
}
