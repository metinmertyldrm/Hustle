using System.ComponentModel.DataAnnotations;

namespace Hustle.Api.Contracts;

public sealed record IngestSignalRequest(
    [Required] string SourceService,
    [Required] string SourceEventId,
    [Required] string Symbol,
    [Required] string Exchange,
    [Required] string Timeframe,
    [Required] string Action,
    [Range(0, 1)] decimal Confidence,
    [Range(typeof(decimal), "0", "79228162514264337593543950335")] decimal Price,
    DateTimeOffset SignalTime,
    IReadOnlyList<string>? Reasons,
    Dictionary<string, object>? Indicators);

public sealed record IngestSignalResponse(Guid SignalId, bool IsDuplicate, int MatchedAlerts);
