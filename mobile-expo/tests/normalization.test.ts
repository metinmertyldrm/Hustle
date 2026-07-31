import assert from 'node:assert/strict'; import test from 'node:test';
import { normalizeSymbol } from '../src/features/analysis/normalization.ts';
test('sembolü boşluklardan arındırır ve büyük harfe dönüştürür', () => assert.equal(normalizeSymbol(' btc-usdt '), 'BTCUSDT'));
