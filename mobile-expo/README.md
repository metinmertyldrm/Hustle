# Hustle Expo mobil uygulaması

Flutter uygulamasının koyu temasını ve yeşil Hustle kimliğini koruyan, Expo Router + React Native + strict TypeScript ile hazırlanmış ilk Expo sürümüdür. Uygulama Expo Go ile Android ve iOS'ta çalışacak şekilde yalnızca Expo Go uyumlu paketler kullanır.

Uygulama Expo SDK 54 kullanır. Analizler Binance kripto verisiyle sınırlıdır;
hisse senetleri (`AAPL`, `MSFT`, `THYAO` gibi) desteklenmez. Piyasalar
ekranındaki dört kripto kartı statik hızlı erişim listesidir. Sistem WebSocket
ile canlı yayın yapmaz: kullanıcı istediğinde son 200 mum alınır, kapanmamış mum
çıkarılır ve son kapanmış mum üzerinden kural tabanlı sinyal hesaplanır.

## Gereksinimler

- Node.js 20.19 veya daha yeni LTS sürümü
- Windows bilgisayarda çalışan Docker Desktop
- Telefonda güncel Expo Go
- Fiziksel cihaz kullanılıyorsa bilgisayar ve telefonun bağlı olduğu aynı yerel ağ

## Windows PowerShell ile kurulum

> **Dizin kontrolü:** Depo kökündeki `package.json`, npm komutlarını bu
> `mobile-expo` workspace'ine yönlendirir. Dolayısıyla kökten `npm install`,
> `npm run web` ve `npm start` kullanılabilir. Expo CLI'ı doğrudan çağıran
> `npx expo start` için ise bu dizine geçin ya da kökten
> `npx expo start mobile-expo` kullanın.

1. Depodan uygulama dizinine geçin:

   ```powershell
   cd mobile-expo
   Test-Path package.json
   ```

   Son komut `True` yazmalıdır. `False` yazarsa `Get-Location` ile mevcut
   dizini kontrol edip deponun içindeki `mobile-expo` klasörüne geçin.

2. Bağımlılıkları kurun:

   ```powershell
   npm install
   ```

3. Örnek ortam dosyasını kopyalayın:

   ```powershell
   Copy-Item .env.example .env
   ```

4. Bilgisayarın yerel IPv4 adresini bulun:

   ```powershell
   ipconfig
   ```

   Etkin Wi-Fi adaptörünün `IPv4 Address` değerini bulun. `.env` içindeki örnek `192.168.1.20` değerini bu adresle değiştirin:

   ```env
   EXPO_PUBLIC_API_BASE_URL=http://192.168.1.20:8000
   ```

5. Expo geliştirme sunucusunu başlatın:

   ```powershell
   npx expo start --offline --clear
   ```

   Yalnızca tarayıcıda çalıştırmak için bunun yerine şu komutu kullanın:

   ```powershell
   npm run web
   ```

6. iPhone veya Android telefonda Expo Go'yu açın ve terminaldeki QR kodunu tarayın. Bağlantı kurulamazsa Windows Güvenlik Duvarı'nda Node.js için özel ağ erişimine izin verildiğini doğrulayın.

## Backend'i Docker Compose ile başlatma

Yeni bir PowerShell penceresinde depo köküne geçip servisleri başlatın:

```powershell
cd C:\path\to\Hustle
Copy-Item .env.example .env
docker compose up --build
```

Servislerin durumunu ve analytics endpoint'ini kontrol edin:

```powershell
docker compose ps
curl.exe "http://localhost:8000/api/v1/analysis/BTCUSDT?interval=1h&limit=200"
```

## API adresi ve cihaz türleri

Uygulama `EXPO_PUBLIC_API_BASE_URL` değerini kullanır ve sondaki `/` karakterini temizler. Değer tanımlı değilse Android emülatörü için uygun olan `http://10.0.2.2:8000` varsayılır.

| Ortam | Önerilen adres |
| --- | --- |
| Android emülatör | `http://10.0.2.2:8000` |
| iOS Simulator | `http://127.0.0.1:8000` |
| Fiziksel iPhone / Android | `http://<BILGISAYARIN-YEREL-IP-ADRESI>:8000` |

**Önemli:** Fiziksel iPhone'daki `localhost` veya `127.0.0.1`, Windows bilgisayarı değil iPhone'un kendisini gösterir; bu adreslerle bilgisayardaki backend'e bağlanamaz. Bilgisayar ve telefon aynı Wi-Fi ağında olmalı, `.env` içinde bilgisayarın yerel IPv4 adresi kullanılmalı ve 8000 portuna güvenlik duvarı erişimi sağlanmalıdır. `.env` değiştikten sonra Expo'yu `npx expo start --clear` ile yeniden başlatın.

Web için `.env` değerini `http://localhost:8000` yapın. Analytics Docker servisi
Expo web'in `http://localhost:8081` origin'ine varsayılan olarak izin verir.

Analiz isteği şu sözleşmeyi kullanır:

```text
GET {API_BASE_URL}/api/v1/analysis/{SYMBOL}?interval={INTERVAL}&limit=200
```

## Kontroller

```powershell
npm test
npm run typecheck
npm run lint
npx expo-doctor
```

## Expo Go sınırlamaları

Bu aşama AsyncStorage ve Expo'nun desteklediği JavaScript/native paketlerle sınırlıdır. Expo Go, uygulamaya özel native modülleri içermez. İleride bildirim servis uzantısı, özel native SDK, arka plan servisi veya Expo Go'da bulunmayan başka bir native modül eklenirse EAS ile bir **development build** oluşturmak gerekecektir.

Son analiz ve takip listesi yalnızca cihazdaki AsyncStorage alanında tutulur; kimlik doğrulama, cihazlar arası eşitleme ve gerçek işlem yürütme bu sürümde yoktur.
