import AsyncStorage from '@react-native-async-storage/async-storage';

const WATCHLIST_KEY = '@hustle/watchlist';

export async function loadWatchlist(): Promise<string[]> {
  const raw = await AsyncStorage.getItem(WATCHLIST_KEY);
  if (!raw) return [];
  try { const value: unknown = JSON.parse(raw); return Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string') : []; }
  catch { return []; }
}

export async function saveWatchlist(items: readonly string[]): Promise<void> {
  await AsyncStorage.setItem(WATCHLIST_KEY, JSON.stringify(items));
}
