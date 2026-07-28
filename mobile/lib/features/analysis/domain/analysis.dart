enum SignalAction {
  safeBuy('SAFE_BUY'), takeProfit('TAKE_PROFIT'), hold('HOLD'), unknown('UNKNOWN');
  const SignalAction(this.wireValue);
  final String wireValue;
  static SignalAction parse(Object? value) => values.firstWhere(
      (item) => item.wireValue == value,
      orElse: () => SignalAction.unknown);
}

class Indicators {
  const Indicators({required this.rsi14, required this.macd, required this.macdSignal,
    required this.macdHistogram, required this.sma20, required this.sma50, required this.ema20});
  final double? rsi14, macd, macdSignal, macdHistogram, sma20, sma50, ema20;
  factory Indicators.fromJson(Object? value) {
    final json = value is Map<String, dynamic> ? value : <String, dynamic>{};
    double? number(String key) => (json[key] as num?)?.toDouble();
    return Indicators(rsi14: number('rsi_14'), macd: number('macd'), macdSignal: number('macd_signal'),
      macdHistogram: number('macd_histogram'), sma20: number('sma_20'), sma50: number('sma_50'), ema20: number('ema_20'));
  }
  Map<String, dynamic> toJson() => {'rsi_14': rsi14, 'macd': macd, 'macd_signal': macdSignal,
    'macd_histogram': macdHistogram, 'sma_20': sma20, 'sma_50': sma50, 'ema_20': ema20};
}

class Analysis {
  const Analysis({required this.sourceService, required this.sourceEventId, required this.symbol,
    required this.exchange, required this.timeframe, required this.action, required this.confidence,
    required this.price, required this.signalTime, required this.reasons, required this.indicators});
  final String sourceService, sourceEventId, symbol, exchange, timeframe;
  final SignalAction action;
  final double confidence, price;
  final DateTime? signalTime;
  final List<String> reasons;
  final Indicators indicators;
  factory Analysis.fromJson(Map<String, dynamic> json) {
    String string(String key, [String fallback = '—']) => json[key] is String && (json[key] as String).isNotEmpty ? json[key] as String : fallback;
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    final reasonValue = json['reasons'];
    return Analysis(sourceService: string('source_service'), sourceEventId: string('source_event_id'),
      symbol: string('symbol'), exchange: string('exchange'), timeframe: string('timeframe'),
      action: SignalAction.parse(json['action']), confidence: number('confidence').clamp(0, 1).toDouble(),
      price: number('price'), signalTime: DateTime.tryParse(string('signal_time', '')),
      reasons: reasonValue is List ? reasonValue.whereType<String>().toList() : const [],
      indicators: Indicators.fromJson(json['indicators']));
  }
  Map<String, dynamic> toJson() => {'source_service': sourceService, 'source_event_id': sourceEventId,
    'symbol': symbol, 'exchange': exchange, 'timeframe': timeframe, 'action': action.wireValue,
    'confidence': confidence, 'price': price, 'signal_time': signalTime?.toIso8601String(),
    'reasons': reasons, 'indicators': indicators.toJson()};
}
