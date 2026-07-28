# Hustle FinTech – Faz 1

Hustle; piyasa verilerinden teknik sinyal üreten Python analiz servisi ile bu
sinyalleri kullanıcı alarm kurallarıyla eşleştiren ASP.NET Core API'sinin Faz 1
iskeletidir. Bu depo eğitim ve paper-trading amaçlıdır; yatırım tavsiyesi vermez.

## VS Code ile açma

Tek tek dosyaları değil, depo kökünü açın:

```bash
git clone <depo-adresi> Hustle
cd Hustle
code Hustle.code-workspace
```

VS Code, önerilen C#, Python ve Docker eklentilerini gösterecektir. En kolay
çalıştırma yöntemi Docker Compose'tur:

```bash
cp .env.example .env
docker compose up --build
```

Servisler:

| Servis | Adres |
| --- | --- |
| .NET API / Swagger | http://localhost:8080/swagger |
| Python analiz / karşılama | http://localhost:8000/ |
| Python analiz / docs | http://localhost:8000/docs |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |

Arka planda başlatıp hemen istek gönderecekseniz Compose'un analiz servisi
hazır olana kadar beklemesini sağlayın. Yalnızca konteynerin `Started` olması,
Uvicorn'un henüz HTTP isteği kabul ettiği anlamına gelmez:

```bash
docker compose up -d --build --wait analytics
curl "http://localhost:8000/"
```

`--wait`, imaja tanımlı `/health` kontrolünün başarılı olmasını bekler. Eski bir
Docker Compose sürümünde `--wait` desteklenmiyorsa `docker compose ps` çıktısında
`analytics` servisi `healthy` olduktan sonra `curl` komutunu çalıştırın. Başlatma
sorunlarını incelemek için `docker compose logs analytics` kullanabilirsiniz.

## Örnek kullanım

```bash
curl "http://localhost:8000/"
curl "http://localhost:8000/api/v1/analysis/BTCUSDT?interval=1h&limit=200"
curl -X POST "http://localhost:8000/api/v1/analysis/BTCUSDT/publish?interval=1h&limit=200"
```

`publish` çağrısı sonucu `DOTNET_SIGNAL_URL` adresine gönderir. Geliştirme
ortamında sinyal kabul endpoint'i açık bırakılmıştır; üretimde
`AnalyticsService` yetkilendirme politikası/JWT etkinleştirilmelidir.

## Yerel geliştirme

Python:

```bash
cd analytics
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

.NET (SDK 8 gerekir):

```bash
dotnet restore Hustle.sln
dotnet run --project backend/Hustle.Api
```

Veritabanı şeması, PostgreSQL konteyneri ilk kez oluşturulurken
`database/001_initial_schema.sql` üzerinden otomatik uygulanır. Mevcut volume
için şemayı yeniden çalıştırmak yerine migration yaklaşımı kullanın.

## Mimari akış

1. Python, Binance kapanmış mumlarını alır ve RSI/MACD/ortalamaları hesaplar.
2. Açıklanabilir skor `SAFE_BUY`, `TAKE_PROFIT` veya `HOLD` üretir.
3. .NET API sinyali idempotent biçimde kaydeder.
4. Aktif alarm kuralları confidence, timeframe, süre ve cooldown'a göre eşleşir.
5. Teslimat ve transactional outbox kaydı aynı transaction içinde oluşturulur.
6. Faz 2'de bir worker outbox kayıtlarını FCM/WebSocket kanalına taşıyabilir.

Kalıcı finansal kayıtların kaynağı PostgreSQL'dir. Redis yalnızca sıcak snapshot,
rate limit, kilit ve kısa ömürlü cache için kullanılmalıdır.
