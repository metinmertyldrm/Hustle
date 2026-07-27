# Hustle FinTech – Faz 1

Hustle; piyasa verilerinden teknik sinyal üreten Python analiz servisi ile bu
sinyalleri kullanıcı alarm kurallarıyla eşleştiren ASP.NET Core API'sinin Faz 1
iskeletidir. Bu depo eğitim ve paper-trading amaçlıdır; yatırım tavsiyesi vermez.

## Visual Studio 2022 ile başlatma (Windows)

> Visual Studio **Code** ile Visual Studio farklı uygulamalardır. Visual Studio'da
> klasörü veya tek tek `.cs` dosyalarını değil, kökteki `Hustle.sln` dosyasını
> açmalısınız.

### Ön koşullar

1. **Visual Studio 2022** kurulumunda **ASP.NET ve web geliştirme** workload'unu
   ve **.NET 8 SDK** bileşenini seçin.
2. **Python 3.12** kurun (`python --version` ile kontrol edin).
3. PostgreSQL ve Redis'i kolayca çalıştırabilmek için **Docker Desktop** kurup
   açın.

### Adım adım (debug edilebilir geliştirme)

1. Depo kökünde PowerShell açıp yalnızca altyapıyı başlatın:

   ```powershell
   Copy-Item .env.example .env
   docker compose up -d postgres redis
   ```

2. Windows Explorer'da `Hustle.sln` dosyasına çift tıklayın veya Visual
   Studio'da **File > Open > Project/Solution** yoluyla bu dosyayı seçin.
3. Solution Explorer'da `Hustle.Api` projesine sağ tıklayıp **Set as Startup
   Project** seçin.
4. Üst araç çubuğundan `http` profilini seçip **F5**'e basın. Swagger
   `http://localhost:8080/swagger` adresinde açılır.
5. Python servisi ayrı bir PowerShell penceresinde başlatın:

   ```powershell
   cd analytics
   py -3.12 -m venv .venv
   .\.venv\Scripts\Activate.ps1
   python -m pip install -r requirements.txt
   python -m uvicorn app.main:app --reload --port 8000
   ```

6. `http://localhost:8000/docs` adresinden Python servisini deneyin. `publish`
   endpoint'i sinyali F5 ile çalışan .NET API'ye gönderir.

İlk PostgreSQL volume'u oluşturulurken örnek `BINANCE:BTCUSDT` varlığı otomatik
eklenir. Daha önce bu projeyi çalıştırdıysanız ve şema/örnek veri eksikse,
**yalnızca kaybetmek istemediğiniz yerel veriniz yoksa** volume'u sıfırlayın:

```powershell
docker compose down -v
docker compose up -d postgres redis
```

### Tek komutla çalıştırma (debugger olmadan)

Tüm servisleri konteyner olarak çalıştırmak isterseniz Visual Studio'nun
Terminal penceresinde depo kökünden şunu çalıştırın:

```powershell
Copy-Item .env.example .env
docker compose up --build
```

Bu yöntemde .NET API de konteynerde çalışır; Visual Studio'da ayrıca F5'e
basmayın, aksi halde `8080` portu çakışır. Durdurmak için `Ctrl+C`, ardından
`docker compose down` kullanın.

### Sık karşılaşılan sorunlar

| Hata | Çözüm |
| --- | --- |
| `Hustle.sln` açılmıyor / proje yüklenemedi | Visual Studio Installer'dan ASP.NET workload ve .NET 8 SDK'yı ekleyin. |
| `connection refused` / PostgreSQL hatası | Docker Desktop'ın açık ve `docker compose ps` çıktısında `postgres` servisinin healthy olduğunu kontrol edin. |
| `address already in use` / 8080 dolu | Ya F5 ile API'yi ya da tüm Compose grubunu çalıştırın; ikisini aynı anda çalıştırmayın. |
| PowerShell script çalıştırmayı engelliyor | Aktivasyon yerine doğrudan `.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000` kullanın. |
| TA-Lib kurulumu hata veriyor | Python 3.12 kullandığınızdan ve `python -m pip install --upgrade pip` çalıştırdığınızdan emin olun. |

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
| Python analiz / docs | http://localhost:8000/docs |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |

## Örnek kullanım

```bash
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
