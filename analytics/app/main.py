from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Annotated, Literal

import httpx
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException, Query, Request
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from redis.asyncio import Redis


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    binance_base_url: str = "https://api.binance.com"
    dotnet_signal_url: str = "http://localhost:8080/api/v1/signals"
    redis_url: str = "redis://localhost:6379/0"
    request_timeout_seconds: float = 10.0


class IndicatorSnapshot(BaseModel):
    rsi_14: float
    macd: float
    macd_signal: float
    macd_histogram: float
    sma_20: float
    sma_50: float
    ema_20: float


class AnalysisResult(BaseModel):
    source_service: str = "hustle-analytics"
    source_event_id: str
    symbol: str
    exchange: str = "BINANCE"
    timeframe: str
    action: Literal["SAFE_BUY", "TAKE_PROFIT", "HOLD"]
    confidence: float = Field(ge=0, le=1)
    price: float
    signal_time: datetime
    reasons: list[str]
    indicators: IndicatorSnapshot


settings = Settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http = httpx.AsyncClient(timeout=settings.request_timeout_seconds)
    app.state.redis = Redis.from_url(settings.redis_url, decode_responses=True)
    yield
    await app.state.http.aclose()
    await app.state.redis.aclose()


app = FastAPI(title="Hustle Analytics API", version="1.0.0", lifespan=lifespan)

ALLOWED_INTERVALS = {"1m", "5m", "15m", "30m", "1h", "4h", "1d"}


async def fetch_closed_klines(request: Request, symbol: str, interval: str, limit: int) -> pd.DataFrame:
    if interval not in ALLOWED_INTERVALS:
        raise HTTPException(400, f"Desteklenmeyen interval. İzin verilenler: {sorted(ALLOWED_INTERVALS)}")

    response = await request.app.state.http.get(
        f"{settings.binance_base_url}/api/v3/klines",
        params={"symbol": symbol.upper(), "interval": interval, "limit": limit},
    )
    if response.status_code != 200:
        raise HTTPException(502, f"Binance market verisi alınamadı: {response.text[:200]}")

    rows = response.json()
    if not isinstance(rows, list):
        raise HTTPException(502, "Binance beklenmeyen bir yanıt döndürdü")
    columns = ["open_time", "open", "high", "low", "close", "volume", "close_time",
               "quote_volume", "trades", "taker_base", "taker_quote", "ignore"]
    frame = pd.DataFrame(rows, columns=columns)
    now_ms = int(datetime.now(timezone.utc).timestamp() * 1000)
    frame = frame[frame["close_time"].astype("int64") < now_ms].copy()
    frame["close"] = pd.to_numeric(frame["close"], errors="coerce")
    if len(frame) < 60 or frame["close"].isna().any():
        raise HTTPException(422, "İndikatörler için en az 60 geçerli, kapanmış mum gerekir")
    return frame


def calculate_signal(frame: pd.DataFrame, symbol: str, interval: str) -> AnalysisResult:
    close_series = frame["close"].astype(np.float64)
    delta = close_series.diff()
    average_gain = delta.clip(lower=0).ewm(alpha=1 / 14, adjust=False, min_periods=14).mean()
    average_loss = -delta.clip(upper=0).ewm(alpha=1 / 14, adjust=False, min_periods=14).mean()
    relative_strength = average_gain / average_loss.replace(0, np.nan)
    rsi = 100 - (100 / (1 + relative_strength))
    rsi = rsi.mask((average_loss == 0) & (average_gain > 0), 100)
    rsi = rsi.mask((average_loss == 0) & (average_gain == 0), 50)

    ema12 = close_series.ewm(span=12, adjust=False, min_periods=12).mean()
    ema26 = close_series.ewm(span=26, adjust=False, min_periods=26).mean()
    macd = ema12 - ema26
    macd_signal = macd.ewm(span=9, adjust=False, min_periods=9).mean()
    macd_hist = macd - macd_signal
    sma20 = close_series.rolling(window=20, min_periods=20).mean()
    sma50 = close_series.rolling(window=50, min_periods=50).mean()
    ema20 = close_series.ewm(span=20, adjust=False, min_periods=20).mean()

    close = close_series.to_numpy()
    rsi = rsi.to_numpy()
    macd = macd.to_numpy()
    macd_signal = macd_signal.to_numpy()
    macd_hist = macd_hist.to_numpy()
    sma20 = sma20.to_numpy()
    sma50 = sma50.to_numpy()
    ema20 = ema20.to_numpy()

    score, reasons = 0.0, []
    if rsi[-1] <= 30:
        score += 0.35
        reasons.append("RSI aşırı satım bölgesinde")
    elif rsi[-1] >= 70:
        score -= 0.35
        reasons.append("RSI aşırı alım bölgesinde")
    if macd[-2] <= macd_signal[-2] and macd[-1] > macd_signal[-1]:
        score += 0.35
        reasons.append("MACD yukarı kesişti")
    elif macd[-2] >= macd_signal[-2] and macd[-1] < macd_signal[-1]:
        score -= 0.35
        reasons.append("MACD aşağı kesişti")
    if close[-1] > ema20[-1] > sma50[-1]:
        score += 0.30
        reasons.append("Fiyat EMA20 ve SMA50 üzerinde")
    elif close[-1] < ema20[-1] < sma50[-1]:
        score -= 0.30
        reasons.append("Fiyat EMA20 ve SMA50 altında")

    action = "SAFE_BUY" if score >= 0.60 else "TAKE_PROFIT" if score <= -0.60 else "HOLD"
    if not reasons:
        reasons.append("Teknik göstergeler nötr")
    close_time = int(frame.iloc[-1]["close_time"])
    return AnalysisResult(
        source_event_id=f"BINANCE:{symbol.upper()}:{interval}:{close_time}",
        symbol=symbol.upper(), timeframe=interval, action=action,
        confidence=round(abs(score), 4), price=float(close[-1]),
        signal_time=datetime.fromtimestamp(close_time / 1000, tz=timezone.utc), reasons=reasons,
        indicators=IndicatorSnapshot(rsi_14=float(rsi[-1]), macd=float(macd[-1]),
            macd_signal=float(macd_signal[-1]), macd_histogram=float(macd_hist[-1]),
            sma_20=float(sma20[-1]), sma_50=float(sma50[-1]), ema_20=float(ema20[-1])),
    )


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "healthy"}


@app.get("/api/v1/analysis/{symbol}", response_model=AnalysisResult)
async def analyze(symbol: str, request: Request,
                  interval: str = "1h", limit: Annotated[int, Query(ge=60, le=1000)] = 200):
    frame = await fetch_closed_klines(request, symbol, interval, limit)
    result = calculate_signal(frame, symbol, interval)
    try:
        await request.app.state.redis.setex(f"analysis:{symbol.upper()}:{interval}", 120, result.model_dump_json())
    except Exception:
        # Cache kesintisi analiz endpoint'ini durdurmamalıdır; kalıcı kayıt .NET/PostgreSQL'dedir.
        pass
    return result


@app.post("/api/v1/analysis/{symbol}/publish", response_model=AnalysisResult)
async def analyze_and_publish(symbol: str, request: Request,
                              interval: str = "1h", limit: Annotated[int, Query(ge=60, le=1000)] = 200):
    result = await analyze(symbol, request, interval, limit)
    response = await request.app.state.http.post(settings.dotnet_signal_url, json=result.model_dump(mode="json"))
    if response.status_code not in (200, 201, 202):
        raise HTTPException(502, f".NET sinyal API isteği başarısız: {response.text[:200]}")
    return result
