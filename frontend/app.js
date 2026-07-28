const form = document.querySelector('#analysis-form');
const symbolInput = document.querySelector('#symbol');
const card = document.querySelector('#signal-card');
const submitButton = form.querySelector('[type="submit"]');
const toast = document.querySelector('#toast');
let interval = '1h';
let deferredInstallPrompt;

const actionLabels = { SAFE_BUY: 'GÜVENLİ AL', TAKE_PROFIT: 'KÂR AL', HOLD: 'BEKLE' };
const intervalLabels = { '15m': '15 DAKİKA', '1h': '1 SAAT', '4h': '4 SAAT', '1d': '1 GÜN' };

function showToast(message) {
  toast.textContent = message;
  toast.classList.add('show');
  window.setTimeout(() => toast.classList.remove('show'), 2800);
}

function formatSymbol(symbol) {
  return symbol.endsWith('USDT') ? `${symbol.slice(0, -4)} / USDT` : symbol;
}

function formatPrice(value) {
  return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'USD', maximumFractionDigits: value < 10 ? 4 : 2 }).format(value);
}

function renderAnalysis(data) {
  const badge = document.querySelector('#signal-badge');
  document.querySelector('#asset-symbol').textContent = formatSymbol(data.symbol);
  document.querySelector('#asset-exchange').textContent = `${data.exchange} • ${intervalLabels[data.timeframe] || data.timeframe.toUpperCase()}`;
  document.querySelector('#asset-logo').textContent = data.symbol.startsWith('BTC') ? '₿' : data.symbol.charAt(0);
  document.querySelector('#asset-price').textContent = formatPrice(data.price);
  document.querySelector('#confidence-value').textContent = `%${Math.round(data.confidence * 100)}`;
  document.querySelector('#confidence-meter').style.width = `${Math.max(3, data.confidence * 100)}%`;
  document.querySelector('#signal-reason').textContent = data.reasons.join(' • ');
  document.querySelector('#signal-time').textContent = `${new Intl.DateTimeFormat('tr-TR', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(data.signal_time))} güncellendi`;
  badge.textContent = actionLabels[data.action] || data.action;
  badge.className = `signal-badge ${data.action === 'SAFE_BUY' ? 'buy' : data.action === 'TAKE_PROFIT' ? 'sell' : 'hold'}`;
  localStorage.setItem('hustle-last-analysis', JSON.stringify(data));
}

async function analyze() {
  const symbol = symbolInput.value.trim().toUpperCase().replace(/[^A-Z0-9]/g, '');
  if (!symbol) return;
  symbolInput.value = symbol;
  card.classList.add('loading');
  submitButton.disabled = true;
  submitButton.textContent = 'Analiz...';
  try {
    const response = await fetch(`/analytics/api/v1/analysis/${encodeURIComponent(symbol)}?interval=${interval}&limit=200`);
    const payload = await response.json();
    if (!response.ok) throw new Error(payload.detail || 'Analiz şu anda alınamadı.');
    renderAnalysis(payload);
    card.scrollIntoView({ behavior: 'smooth', block: 'center' });
  } catch (error) {
    showToast(error.message || 'Bağlantı kurulamadı. Lütfen tekrar deneyin.');
  } finally {
    card.classList.remove('loading');
    submitButton.disabled = false;
    submitButton.textContent = 'Analiz et';
  }
}

form.addEventListener('submit', (event) => { event.preventDefault(); analyze(); });
document.querySelectorAll('[data-interval]').forEach((button) => button.addEventListener('click', () => {
  interval = button.dataset.interval;
  document.querySelectorAll('[data-interval]').forEach((item) => item.classList.toggle('active', item === button));
}));
document.querySelectorAll('.coin[data-symbol]').forEach((button) => button.addEventListener('click', () => {
  symbolInput.value = button.dataset.symbol;
  window.scrollTo({ top: 80, behavior: 'smooth' });
  analyze();
}));
document.querySelector('#refresh-button').addEventListener('click', analyze);

window.addEventListener('beforeinstallprompt', (event) => { event.preventDefault(); deferredInstallPrompt = event; });
document.querySelector('#install-button').addEventListener('click', async () => {
  if (!deferredInstallPrompt) {
    showToast('Tarayıcı menüsünden “Ana ekrana ekle” seçeneğini kullanabilirsin.');
    return;
  }
  deferredInstallPrompt.prompt();
  await deferredInstallPrompt.userChoice;
  deferredInstallPrompt = null;
});

try {
  const cached = JSON.parse(localStorage.getItem('hustle-last-analysis'));
  if (cached) { interval = cached.timeframe; renderAnalysis(cached); }
} catch { localStorage.removeItem('hustle-last-analysis'); }

if ('serviceWorker' in navigator) window.addEventListener('load', () => navigator.serviceWorker.register('/service-worker.js'));
