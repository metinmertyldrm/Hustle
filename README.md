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

> **Not:** Deponun tamamını (Python, .NET, SQL ve Docker dosyalarıyla birlikte)
> incelemek için VS Code önerilir. Visual Studio 2022 kullanıyorsanız
> `Hustle.sln` dosyasını açabilirsiniz; bu görünüm yalnızca .NET projelerini
> gösterir.

## Gereksinimler

Projeyi en kısa yoldan çalıştırmak için şunlar yeterlidir:

- Docker Desktop veya Docker Engine ile Docker Compose v2
- Depoyu incelemek için VS Code ve önerilen eklentiler

Testleri Docker dışında yerel olarak çalıştırmak isterseniz ayrıca Python 3.12+
ve .NET 8 SDK gerekir. Kurulumları aşağıdaki komutlarla kontrol edebilirsiniz:

```bash
docker --version
docker compose version
python --version
dotnet --version
```

## İlk çalıştırma ve elle kontrol

Depo kökünde aşağıdaki komutları çalıştırın:

```bash
cp .env.example .env
docker compose up -d --build --wait
docker compose ps
```

Tüm servislerin `running`/`healthy` görünmesinden sonra tarayıcıdan şu adresleri
açabilirsiniz:

- Hustle mobil uygulaması: http://localhost:3000
- .NET Swagger: http://localhost:8080/swagger
- Python analiz Swagger: http://localhost:8000/docs
- Python servis bilgisi: http://localhost:8000/

### Telefonda uygulama olarak kullanma

Hustle arayüzü bir Progressive Web App (PWA) olarak hazırlanmıştır. Bilgisayar
ve telefon aynı Wi-Fi ağındayken bilgisayarınızın yerel IP adresini öğrenin ve
telefondan `http://BILGISAYAR-IP:3000` adresini açın. Ardından Android/Chrome'da
**Uygulamayı yükle**, iPhone/Safari'de **Paylaş → Ana Ekrana Ekle** seçeneğini
kullanın. Telefon erişimi için güvenlik duvarında 3000 portuna yerel ağ erişimi
verilmesi gerekebilir.

> PWA'nın service worker ve çevrimdışı özellikleri, `localhost` dışında güvenli
> bir HTTPS adresi gerektirir. Canlı ortamda 3000 portunu doğrudan açmak yerine
> uygulamayı HTTPS sağlayan bir alan adı/reverse proxy arkasında yayınlayın.

Terminalden temel sağlık ve analiz kontrolleri (Bash, Git Bash veya WSL):

```bash
curl --fail http://localhost:8080/health
curl --fail http://localhost:8000/health
curl --fail "http://localhost:8000/api/v1/analysis/BTCUSDT?interval=1h&limit=200"
```

Windows PowerShell'da `curl`, `Invoke-WebRequest` için bir diğer addır ve
`--fail` seçeneğini kabul etmez. PowerShell'dan aynı kontrolleri gerçek curl
programını açıkça çağırarak yapın:

```powershell
curl.exe --fail http://localhost:8080/health
curl.exe --fail http://localhost:8000/health
curl.exe --fail "http://localhost:8000/api/v1/analysis/BTCUSDT?interval=1h&limit=200"
```

Alternatif olarak PowerShell'ın kendi komutunu kullanabilirsiniz; başarısız HTTP
yanıtları hata üretir, başarılı yanıtların gövdesi ekrana yazdırılır:

```powershell
Invoke-RestMethod http://localhost:8080/health
Invoke-RestMethod http://localhost:8000/health
Invoke-RestMethod "http://localhost:8000/api/v1/analysis/BTCUSDT?interval=1h&limit=200"
```

`publish` akışının çalışması için gönderilen varlığın `assets` tablosunda kayıtlı
olması gerekir. Yeni oluşturulmuş veritabanına örnek BTC varlığını ekleyip uçtan
uca sinyal akışını şu şekilde deneyebilirsiniz:

```bash
docker compose exec -T postgres psql -U hustle -d hustle <<'SQL'
INSERT INTO assets (symbol, name, asset_type, exchange, quote_currency)
VALUES ('BTCUSDT', 'Bitcoin / Tether', 'crypto', 'BINANCE', 'USDT')
ON CONFLICT (exchange, symbol) DO NOTHING;
SQL

curl --fail -X POST \
  "http://localhost:8000/api/v1/analysis/BTCUSDT/publish?interval=1h&limit=200"

docker compose exec -T postgres psql -U hustle -d hustle \
  -c "SELECT a.symbol, s.action, s.confidence, s.signal_time FROM market_signals s JOIN assets a ON a.id = s.asset_id ORDER BY s.signal_time DESC LIMIT 5;"
```

Logları izlemek veya ortamı kapatmak için:

```bash
docker compose logs -f api analytics
docker compose down
```

Veritabanı verilerini de tamamen silerek temiz başlangıç yapmak için
`docker compose down -v` kullanın. Bu komut yerel PostgreSQL volume'ündeki bütün
Hustle verilerini siler.

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

Python testleri:

```bash
cd analytics
pip install -r requirements-dev.txt
pytest
```

Başarılı çalışmada pytest iki testin geçtiğini raporlar. Bu testler nötr piyasa
sinyalini ve geçersiz zaman aralığının reddedilmesini kontrol eder.

.NET (SDK 8 gerekir):

```bash
dotnet restore Hustle.sln
dotnet run --project backend/Hustle.Api
```

.NET testleri depo kökünden çalıştırılır:

```bash
dotnet test Hustle.sln
```

Başarılı çalışmada sinyal kaydı, tekrar eden sinyal, alarm eşleşmesi, filtreler,
cooldown ve geçersiz action senaryolarını kapsayan beş test geçer. Ayrıntılı test
çıktısı için komuta `--logger "console;verbosity=detailed"` ekleyebilirsiniz.

## Sık karşılaşılan sorunlar

- `docker compose up --wait` desteklenmiyorsa `docker compose up -d --build`
  çalıştırın ve `docker compose ps` çıktısında servislerin hazır olmasını bekleyin.
- Analiz isteği Binance bağlantısı nedeniyle `502` dönerse internet/DNS erişimini
  ve `docker compose logs analytics` çıktısını kontrol edin.
- `publish` isteği “varlığı kayıtlı değil” döndürürse yukarıdaki örnek `INSERT`
  komutunu çalıştırın.
- Port kullanım hatasında 8000, 8080, 5432 ve 6379 portlarını kullanan yerel
  süreçleri durdurun veya `docker-compose.yml` içindeki host portlarını değiştirin.
- Windows PowerShell'de `cp .env.example .env` yerine
  `Copy-Item .env.example .env` kullanabilirsiniz.

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
