import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

String normalizeSymbol(String value) => value.trim().toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

class WatchlistNotifier extends StateNotifier<List<String>> {
  WatchlistNotifier() : super(const []) { _load(); }
  static const key = 'watchlist';
  Future<void> _load() async => state = (await SharedPreferences.getInstance()).getStringList(key) ?? const [];
  Future<bool> add(String value) async {
    final symbol = normalizeSymbol(value);
    if (symbol.isEmpty || state.contains(symbol)) return false;
    state = [...state, symbol]; await (await SharedPreferences.getInstance()).setStringList(key, state); return true;
  }
  Future<void> remove(String symbol) async {
    state = state.where((item) => item != symbol).toList();
    await (await SharedPreferences.getInstance()).setStringList(key, state);
  }
}
final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<String>>((ref) => WatchlistNotifier());
