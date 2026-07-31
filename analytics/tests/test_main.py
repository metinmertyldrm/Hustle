import asyncio
from datetime import datetime, timedelta, timezone

import numpy as np
import pandas as pd
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.main import app, calculate_signal, fetch_closed_klines


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


def test_fetch_closed_klines_rejects_unsupported_interval():
    error = None
    try:
        asyncio.run(fetch_closed_klines(None, "BTCUSDT", "2h", 200))
    except HTTPException as caught_error:
        error = caught_error
    else:
        raise AssertionError("Unsupported interval was accepted")

    assert error is not None
    assert error.status_code == 400
    assert "Desteklenmeyen interval" in error.detail


def test_cors_allows_configured_origin_on_get():
    response = TestClient(app).get("/health", headers={"Origin": "http://localhost:8081"})

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:8081"


def test_cors_allows_configured_origin_preflight():
    response = TestClient(app).options(
        "/api/v1/analysis/BTCUSDT",
        headers={
            "Origin": "http://127.0.0.1:8081",
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "Content-Type",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://127.0.0.1:8081"


def test_cors_does_not_allow_unconfigured_origin():
    response = TestClient(app).get("/health", headers={"Origin": "https://example.com"})

    assert response.status_code == 200
    assert "access-control-allow-origin" not in response.headers
