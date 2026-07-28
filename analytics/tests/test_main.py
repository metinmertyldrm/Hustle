from datetime import datetime, timedelta, timezone

import numpy as np
import pandas as pd
import pytest
from fastapi import HTTPException

from app.main import calculate_signal, fetch_closed_klines


def make_frame(prices: np.ndarray) -> pd.DataFrame:
    start = datetime(2026, 1, 1, tzinfo=timezone.utc)
    close_times = [int((start + timedelta(hours=index)).timestamp() * 1000) for index in range(len(prices))]
    return pd.DataFrame({"close": prices, "close_time": close_times})


def test_calculate_signal_is_hold_for_flat_market():
    result = calculate_signal(make_frame(np.full(80, 100.0)), "ETHUSDT", "4h")

    assert result.action == "HOLD"
    assert result.confidence == 0
    assert result.indicators.rsi_14 == 50
    assert result.reasons == ["Teknik göstergeler nötr"]
    assert result.source_event_id.endswith(":4h:1767510000000")
    assert result.symbol == "ETHUSDT"


@pytest.mark.asyncio
async def test_fetch_closed_klines_rejects_unsupported_interval():
    with pytest.raises(HTTPException) as error:
        await fetch_closed_klines(None, "BTCUSDT", "2h", 200)

    assert error.value.status_code == 400
    assert "Desteklenmeyen interval" in error.value.detail
