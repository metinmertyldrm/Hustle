using Hustle.Api.Contracts;
using Hustle.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace Hustle.Api.Controllers;

[ApiController]
[Route("api/v1/signals")]
public sealed class SignalsController(ISignalIngestionService signalService) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType<IngestSignalResponse>(StatusCodes.Status202Accepted)]
    public async Task<ActionResult<IngestSignalResponse>> Ingest(
        [FromBody] IngestSignalRequest request, CancellationToken cancellationToken)
    {
        var result = await signalService.IngestAsync(request, cancellationToken);
        return Accepted(result);
    }
}
