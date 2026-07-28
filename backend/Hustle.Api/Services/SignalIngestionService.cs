using System.Text.Json;
using Hustle.Api.Contracts;
using Hustle.Api.Data;
using Hustle.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Hustle.Api.Services;

public interface ISignalIngestionService
{
    Task<IngestSignalResponse> IngestAsync(IngestSignalRequest request, CancellationToken cancellationToken);
}

public sealed class SignalIngestionService(FintechDbContext db) : ISignalIngestionService
{
    private static readonly HashSet<string> Actions = ["SAFE_BUY", "TAKE_PROFIT", "HOLD"];

    public async Task<IngestSignalResponse> IngestAsync(
        IngestSignalRequest request, CancellationToken cancellationToken)
    {
        var action = request.Action.ToUpperInvariant();
        if (!Actions.Contains(action))
            throw new ArgumentException("Action SAFE_BUY, TAKE_PROFIT veya HOLD olmalıdır.", nameof(request));

        var duplicate = await db.MarketSignals.AsNoTracking().FirstOrDefaultAsync(
            signal => signal.SourceService == request.SourceService &&
                      signal.SourceEventId == request.SourceEventId, cancellationToken);
        if (duplicate is not null)
            return new IngestSignalResponse(duplicate.Id, true, 0);

        var symbol = request.Symbol.ToUpperInvariant();
        var exchange = request.Exchange.ToUpperInvariant();
        var asset = await db.Assets.SingleOrDefaultAsync(
            candidate => candidate.Symbol == symbol && candidate.Exchange == exchange, cancellationToken)
            ?? throw new KeyNotFoundException($"{exchange}:{symbol} varlığı kayıtlı değil.");

        await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
        var signal = new MarketSignal
        {
            Id = Guid.NewGuid(), AssetId = asset.Id, SourceService = request.SourceService,
            SourceEventId = request.SourceEventId, Action = action, Timeframe = request.Timeframe,
            Confidence = request.Confidence, Price = request.Price, SignalTime = request.SignalTime,
            Reasons = JsonSerializer.Serialize(request.Reasons ?? []),
            Indicators = JsonSerializer.Serialize(request.Indicators ?? []),
            RawPayload = JsonSerializer.Serialize(request)
        };
        db.MarketSignals.Add(signal);

        var now = DateTimeOffset.UtcNow;
        List<AlertRule> rules = [];
        if (action != "HOLD")
        {
            var candidateRules = await db.AlertRules.Where(rule =>
                rule.AssetId == asset.Id && rule.IsActive && rule.ExpectedAction == action &&
                rule.MinConfidence <= request.Confidence &&
                (rule.Timeframe == null || rule.Timeframe == request.Timeframe))
                .ToListAsync(cancellationToken);

            rules = candidateRules
                .Where(rule =>
                    (rule.ExpiresAt == null || rule.ExpiresAt > now) &&
                    (rule.LastTriggeredAt == null ||
                     rule.LastTriggeredAt.Value.AddMinutes(rule.CooldownMinutes) <= now))
                .ToList();
        }

        foreach (var rule in rules)
        {
            var delivery = new AlertDelivery
            {
                Id = Guid.NewGuid(), AlertRuleId = rule.Id, SignalId = signal.Id, UserId = rule.UserId,
                DedupeKey = $"{rule.Id:N}:{signal.Id:N}"
            };
            db.AlertDeliveries.Add(delivery);
            db.NotificationOutbox.Add(new NotificationOutbox
            {
                Id = Guid.NewGuid(), AlertDeliveryId = delivery.Id,
                Payload = JsonSerializer.Serialize(new
                {
                    deliveryId = delivery.Id, userId = rule.UserId, signalId = signal.Id,
                    symbol, action, request.Confidence, request.Price, request.Reasons
                })
            });
            rule.LastTriggeredAt = now;
        }

        await db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return new IngestSignalResponse(signal.Id, false, rules.Count);
    }
}
