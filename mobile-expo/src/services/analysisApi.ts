import type { Analysis, Indicators, SignalAction } from '../types/analysis.ts';
import { normalizeSymbol } from '../features/analysis/normalization.ts';
import { API_BASE_URL } from './config.ts';

const TIMEOUT_MS = 12_000;
const VALID_ACTIONS = new Set<SignalAction>(['SAFE_BUY', 'TAKE_PROFIT', 'HOLD']);

export class AnalysisApiError extends Error {}

export function buildAnalysisUrl(baseUrl: string, symbol: string, interval: string): string {
  const root = baseUrl.replace(/\/+$/, '');
  return `${root}/api/v1/analysis/${encodeURIComponent(normalizeSymbol(symbol))}?interval=${encodeURIComponent(interval)}&limit=200`;
}

export function errorMessageForStatus(status: number): string {
  if (status === 400 || status === 422) return 'Sembol veya zaman aralığı geçersiz.';
  if (status === 502) return 'Piyasa veri sağlayıcısına ulaşılamıyor.';
  return 'Analiz servisi isteği tamamlayamadı.';
}

function nullableNumber(value: unknown): number | null {
  return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

export function parseAnalysis(value: unknown): Analysis {
  if (!value || typeof value !== 'object') throw new AnalysisApiError('Sunucudan geçersiz veri alındı.');
  const item = value as Record<string, unknown>;
  if (typeof item.symbol !== 'string' || !item.symbol || typeof item.price !== 'number') {
    throw new AnalysisApiError('Sunucudan geçersiz veri alındı.');
  }
  const rawIndicators = item.indicators && typeof item.indicators === 'object'
    ? item.indicators as Record<string, unknown> : {};
  const indicators: Indicators = {
    rsi_14: nullableNumber(rawIndicators.rsi_14), macd: nullableNumber(rawIndicators.macd),
    macd_signal: nullableNumber(rawIndicators.macd_signal), macd_histogram: nullableNumber(rawIndicators.macd_histogram),
    sma_20: nullableNumber(rawIndicators.sma_20), sma_50: nullableNumber(rawIndicators.sma_50), ema_20: nullableNumber(rawIndicators.ema_20),
  };
  const action = typeof item.action === 'string' && VALID_ACTIONS.has(item.action as SignalAction)
    ? item.action as SignalAction : 'UNKNOWN';
  return {
    source_service: typeof item.source_service === 'string' ? item.source_service : '—',
    source_event_id: typeof item.source_event_id === 'string' ? item.source_event_id : '—',
    symbol: item.symbol,
    exchange: typeof item.exchange === 'string' ? item.exchange : '—',
    timeframe: typeof item.timeframe === 'string' ? item.timeframe : '—', action,
    confidence: typeof item.confidence === 'number' ? Math.max(0, Math.min(1, item.confidence)) : 0,
    price: item.price, signal_time: typeof item.signal_time === 'string' ? item.signal_time : null,
    reasons: Array.isArray(item.reasons) ? item.reasons.filter((reason): reason is string => typeof reason === 'string') : [], indicators,
  };
}

export async function fetchAnalysis(symbol: string, interval: string, fetcher: typeof fetch = fetch): Promise<Analysis> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetcher(buildAnalysisUrl(API_BASE_URL, symbol, interval), { signal: controller.signal });
    if (!response.ok) throw new AnalysisApiError(errorMessageForStatus(response.status));
    let json: unknown;
    try { json = await response.json(); } catch { throw new AnalysisApiError('Sunucudan geçersiz veri alındı.'); }
    return parseAnalysis(json);
  } catch (error) {
    if (error instanceof AnalysisApiError) throw error;
    if (error instanceof Error && error.name === 'AbortError') {
      throw new AnalysisApiError('İstek zaman aşımına uğradı. Lütfen yeniden deneyin.');
    }
    throw new AnalysisApiError('Analiz servisine bağlanılamadı. Ağ bağlantınızı ve API adresini kontrol edin.');
  } finally { clearTimeout(timer); }
}
