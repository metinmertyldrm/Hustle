import assert from 'node:assert/strict'; import test from 'node:test';
import { buildAnalysisUrl, errorMessageForStatus } from '../src/services/analysisApi.ts';
test('analiz URL’sini beklenen endpoint ve parametrelerle kurar', () => assert.equal(buildAnalysisUrl('http://test:8000/', ' btcusdt ', '1h'), 'http://test:8000/api/v1/analysis/BTCUSDT?interval=1h&limit=200'));
test('API hata kodlarını Türkçe mesajlara çevirir', () => { assert.equal(errorMessageForStatus(400), 'Sembol veya zaman aralığı geçersiz.'); assert.equal(errorMessageForStatus(422), 'Sembol veya zaman aralığı geçersiz.'); assert.equal(errorMessageForStatus(502), 'Piyasa veri sağlayıcısına ulaşılamıyor.'); assert.equal(errorMessageForStatus(500), 'Analiz servisi isteği tamamlayamadı.'); });
