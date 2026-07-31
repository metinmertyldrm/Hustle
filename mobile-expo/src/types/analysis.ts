export type SignalAction = 'SAFE_BUY' | 'TAKE_PROFIT' | 'HOLD' | 'UNKNOWN';

export interface Indicators {
  rsi_14: number | null;
  macd: number | null;
  macd_signal: number | null;
  macd_histogram: number | null;
  sma_20: number | null;
  sma_50: number | null;
  ema_20: number | null;
}

export interface Analysis {
  source_service: string;
  source_event_id: string;
  symbol: string;
  exchange: string;
  timeframe: string;
  action: SignalAction;
  confidence: number;
  price: number;
  signal_time: string | null;
  reasons: string[];
  indicators: Indicators;
}

export type AnalysisState =
  | { status: 'idle'; data: Analysis | null }
  | { status: 'loading'; data: Analysis | null }
  | { status: 'success'; data: Analysis }
  | { status: 'error'; data: Analysis | null; message: string };
