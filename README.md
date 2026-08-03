# Hustle FinTech – Faz 1

Hustle; piyasa verilerinden teknik sinyal üreten Python analiz servisi ile bu
sinyalleri kullanıcı alarm kurallarıyla eşleştiren ASP.NET Core API'sinin Faz 1
iskeletidir. Bu depo eğitim ve paper-trading amaçlıdır; yatırım tavsiyesi vermez.

## Veri kapsamı ve analiz yöntemi

Mevcut analiz veri sağlayıcısı Binance'tır ve yalnızca Binance kripto pariteleri
desteklenir. Hisse senedi desteği yoktur; `AAPL`, `MSFT` ve `THYAO` gibi
semboller desteklenmez. Expo uygulamasının Piyasalar ekranındaki `BTCUSDT`,
`ETHUSDT`, `SOLUSDT` ve `BNBUSDT` kartları dinamik bir piyasa taraması değil,
şimdilik statik bir hızlı erişim listesidir.

Her **Analiz et** isteğinde Binance `/api/v3/klines` endpoint'inden son 200 mum
alınır. Henüz kapanmamış mum çıkarılır ve hesaplama için en az 60 kapanmış mum
aranır. Bu akış WebSocket veya gerçek zamanlı streaming değildir; sonuç, istek
anındaki son kapanmış mum üzerinden üretilir.

Servis RSI 14, MACD 12/26/9, EMA20, SMA20 ve SMA50 hesaplar. Açıklanabilir kural
skoru şu şekilde oluşturulur:

- RSI ≤ 30 ise `+0.35`, RSI ≥ 70 ise `-0.35`;
- MACD yukarı kesişiminde `+0.35`, aşağı kesişiminde `-0.35`;
- fiyat > EMA20 > SMA50 ise `+0.30`;
- fiyat < EMA20 < SMA50 ise `-0.30`.

Skor ≥ `0.60` olduğunda `SAFE_BUY`, skor ≤ `-0.60` olduğunda `TAKE_PROFIT`,
diğer durumlarda `HOLD` döner. API'deki `confidence` alanı istatistiksel başarı
olasılığı veya tahmin doğruluğu değildir; `abs(score)` tabanlı **sinyal gücünü**
ifade eder.

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

Mobil uygulama için [Flutter stable](https://docs.flutter.dev/get-started/install) (Dart dahil), Android Studio/Android SDK ve iOS geliştirme için macOS üzerinde Xcode/CocoaPods kurun. `flutter doctor` ile kurulumu doğrulayın.

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

## Expo uygulamasını çalıştırma

Depo kökündeki npm workspace yapılandırması komutları `mobile-expo/`
uygulamasına yönlendirir. Bu nedenle Windows PowerShell'da kullanıcının hata
aldığı depo kökünden doğrudan şu komutlar çalıştırılabilir:

```powershell
cd C:\projeler\Hustle-main
npm install
Copy-Item mobile-expo\.env.example mobile-expo\.env
npm run web
```

Telefon veya emülatör için kökten `npm start -- --clear` komutunu kullanın:

```powershell
npm start -- --clear
```

Aynı Wi-Fi ağındaki fiziksel cihaz için ngrok gerektirmeyen LAN modu önerilir:

```powershell
npm run start:lan -- --clear
```

Telefon ve bilgisayar farklı ağlardaysa tünel modu kökten şu komutla
başlatılabilir:

```powershell
npm run start:tunnel -- --clear
```

`failed to start tunnel` / `remote gone away` mesajı, Metro veya uygulama
hatasından ziyade Expo'nun kullandığı ngrok bağlantısının kurulamadığını
gösterir. Önce ngrok durum sayfasını ve VPN/proxy/kurumsal güvenlik duvarını
kontrol edin; aynı ağdaysanız tüneli tekrar denemek yerine `start:lan` kullanın.
Yalnızca bu bilgisayardaki emülatör ya da web için `npm run start:localhost`
seçeneği de kullanılabilir. Kökten doğrudan `npx expo start --tunnel` çalıştırmak
yerine yukarıdaki npm betiklerini kullanmak, Expo'nun yanlışlıkla depo kökündeki
backend `.env` dosyasını yüklemesini de önler.

`npx expo start` Expo CLI'ı geçerli dizinde doğrudan başlattığı için uygulamanın
kökünü otomatik olarak `mobile-expo/` yapmaz. Bu komutu özellikle kullanmak
isterseniz önce `cd mobile-expo` çalıştırın veya proje dizinini açıkça verin:

```powershell
npx expo start mobile-expo --clear
```

Ayrıntılı cihaz ve API adresi kurulumu için
[`mobile-expo/README.md`](mobile-expo/README.md) belgesine bakın.

## İlk çalıştırma ve elle kontrol

Depo kökünde aşağıdaki komutları çalıştırın:

```bash
cp .env.example .env
docker compose up -d --build --wait
docker compose ps
```

Tüm servislerin `running`/`healthy` görünmesinden sonra tarayıcıdan şu adresleri
açabilirsiniz:

- .NET Swagger: http://localhost:8080/swagger
- Python analiz Swagger: http://localhost:8000/docs
- Python servis bilgisi: http://localhost:8000/

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
sinyalini, geçersiz zaman aralığının reddedilmesini ve analytics CORS davranışını
kontrol eder.

## Expo web CORS yapılandırması

Analytics servisi varsayılan olarak Expo web geliştirme origin'leri
`http://localhost:8081` ve `http://127.0.0.1:8081` için CORS yanıtı verir.
İzinli origin'leri virgülle ayrılmış kesin origin listesiyle değiştirebilirsiniz:

```env
CORS_ALLOWED_ORIGINS=http://localhost:8081,http://127.0.0.1:8081
```

Tüm origin'lere açık `*` varsayımı kullanılmaz; production origin'lerini açıkça
listeleyin.

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


## Flutter mobil uygulaması

`mobile/` içindeki null-safe Flutter uygulaması Android ve iOS odaklıdır. Koyu temalı ana sayfa analiz, yerel son analiz önbelleği ve yerel takip listesi sunar. Native mobil HTTP istekleri browser CORS politikasına tabi olmadığından backend'e CORS eklenmemiştir.

Önce backend'i depo kökünde başlatın:

```bash
cp .env.example .env
docker compose up -d --build --wait
```

Bağımlılıkları kurup kalite kontrollerini çalıştırın:

```bash
cd mobile
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

### Android emulator

Android Studio'dan bir emulator başlatın. Varsayılan adres Android emulator host köprüsü olan `http://10.0.2.2:8000` değeridir:

```bash
cd mobile
flutter run -d emulator-5554
flutter build apk --debug
```

Debug APK `mobile/build/app/outputs/flutter-apk/` altında üretilir ve Git tarafından yok sayılır.

### iOS simulator

macOS ve Xcode gerekir. Varsayılan adres `http://127.0.0.1:8000` değeridir:

```bash
cd mobile
open -a Simulator
flutter run -d ios
```

### Fiziksel Android veya iPhone

Telefon ve bilgisayar aynı yerel ağda olmalıdır. Bilgisayarın IP adresini macOS/Linux'ta `ipconfig getifaddr en0` veya `hostname -I`, Windows PowerShell'da `Get-NetIPAddress -AddressFamily IPv4` ile bulun. Güvenlik duvarında 8000 portuna yalnızca güvenilen yerel ağdan izin verin ve cihazı şu şekilde çalıştırın:

```bash
cd mobile
flutter devices
flutter run -d <cihaz-kimliği> --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

`192.168.1.20` yalnızca örnektir; bilgisayarınızın gerçek yerel IP adresiyle değiştirin. Her ortamda adres merkezi olarak `API_BASE_URL` ile değiştirilebilir:

```bash
flutter run --dart-define=API_BASE_URL=https://analytics.example.com
```

Android cleartext HTTP yalnızca debug derlemede açıktır. Release derlemesi ve gerçek üretim dağıtımı geçerli sertifikalı **HTTPS** API kullanmalıdır. iPhone üzerinde HTTP geliştirme yerine yerel HTTPS reverse proxy/tünel kullanılması önerilir. Keystore, provisioning profile ve sertifikalar depoya eklenmemelidir.
