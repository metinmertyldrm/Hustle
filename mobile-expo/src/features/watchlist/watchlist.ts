import { normalizeSymbol } from '../analysis/normalization.ts';

export function addUniqueSymbol(items: readonly string[], value: string): string[] {
  const symbol = normalizeSymbol(value);
  if (!symbol || items.includes(symbol)) return [...items];
  return [...items, symbol];
}

export function removeSymbol(items: readonly string[], symbol: string): string[] {
  return items.filter((item) => item !== symbol);
}
