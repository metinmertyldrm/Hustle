namespace Hustle.Api.Models;

public sealed class Asset
{
    public Guid Id { get; set; }
    public required string Symbol { get; set; }
    public required string Exchange { get; set; }
}

public sealed class MarketSignal
{
    public Guid Id { get; set; }
    public Guid AssetId { get; set; }
    public required string SourceService { get; set; }
    public required string SourceEventId { get; set; }
    public required string Action { get; set; }
    public required string Timeframe { get; set; }
    public decimal Confidence { get; set; }
    public decimal Price { get; set; }
    public DateTimeOffset SignalTime { get; set; }
    public string Reasons { get; set; } = "[]";
    public string Indicators { get; set; } = "{}";
    public string RawPayload { get; set; } = "{}";
}

public sealed class AlertRule
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid AssetId { get; set; }
    public required string ExpectedAction { get; set; }
    public string? Timeframe { get; set; }
    public decimal MinConfidence { get; set; }
    public int CooldownMinutes { get; set; }
    public bool IsActive { get; set; }
    public DateTimeOffset? ExpiresAt { get; set; }
    public DateTimeOffset? LastTriggeredAt { get; set; }
}

public sealed class AlertDelivery
{
    public Guid Id { get; set; }
    public Guid AlertRuleId { get; set; }
    public Guid SignalId { get; set; }
    public Guid UserId { get; set; }
    public required string DedupeKey { get; set; }
    public string Status { get; set; } = "pending";
}

public sealed class NotificationOutbox
{
    public Guid Id { get; set; }
    public Guid AlertDeliveryId { get; set; }
    public string EventType { get; set; } = "alert.created";
    public required string Payload { get; set; }
}
