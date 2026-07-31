import assert from 'node:assert/strict'; import test from 'node:test';
import { addUniqueSymbol } from '../src/features/watchlist/watchlist.ts';
test('takip listesinde tekrar eden sembolü engeller', () => { const first = addUniqueSymbol([], ' btc-usdt '); assert.deepEqual(first, ['BTCUSDT']); assert.deepEqual(addUniqueSymbol(first, 'BTCUSDT'), ['BTCUSDT']); });
