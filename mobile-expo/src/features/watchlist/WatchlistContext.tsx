import { createContext, useCallback, useContext, useEffect, useMemo, useState, type PropsWithChildren } from 'react';
import { loadWatchlist, saveWatchlist } from '../../storage/watchlistStorage';
import { addUniqueSymbol, removeSymbol } from './watchlist';

interface WatchlistContextValue { items: string[]; add: (value: string) => boolean; remove: (symbol: string) => void }
const WatchlistContext = createContext<WatchlistContextValue | null>(null);

export function WatchlistProvider({ children }: PropsWithChildren) {
  const [items, setItems] = useState<string[]>([]);
  useEffect(() => { void loadWatchlist().then(setItems); }, []);
  const add = useCallback((value: string) => {
    let added = false;
    setItems((current) => { const next = addUniqueSymbol(current, value); added = next.length > current.length; if (added) void saveWatchlist(next); return next; });
    return added;
  }, []);
  const remove = useCallback((symbol: string) => setItems((current) => { const next = removeSymbol(current, symbol); void saveWatchlist(next); return next; }), []);
  const value = useMemo(() => ({ items, add, remove }), [items, add, remove]);
  return <WatchlistContext.Provider value={value}>{children}</WatchlistContext.Provider>;
}

export function useWatchlist(): WatchlistContextValue {
  const context = useContext(WatchlistContext);
  if (!context) throw new Error('useWatchlist, WatchlistProvider içinde kullanılmalıdır.');
  return context;
}
