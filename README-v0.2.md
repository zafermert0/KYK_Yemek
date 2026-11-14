# KYK Yemek – v0.2.0 (test)

Mevcut `main.dart` ve `.github/workflows/android.yml` dosyalarını değiştirin. `android_support.zip` dosyasını repo köküne olduğu gibi yükleyin; GitHub Actions açacaktır. Kodun geri kalanını ve MIT lisansını koruyun. Önce main.dart ve android_support.zip yükleyin; sonra workflow dosyasını değiştirin. İlk yükleme eski iş akışını tetiklerse yeni iş akışı çalışmasını esas alın. APK Actions > son başarılı çalışma > Artifacts altında bulunur.

## Sınırlar

- Gerçek Flutter/Android derlemesi henüz çalıştırılmadı. Kodun parantez yapısı, Python Android kurulum betiği ve üretilen XML test edildi.
- yurtmenu.net canlı erişimi izin doğrulanana kadar kapalıdır. İzinli HTTPS JSON uç noktası ayarlardan tanımlanabilir; biçim `{ "2026-11-14": { "breakfast": ["..."], "dinner": ["..."] } }`. Başarılı veriler yerelde saklanır. Sunucu gerekmez. Otomatik çekme uygulama açılışı ve devam etmesi sırasında en fazla saatte bir; manuel yenileme ayrı. Uygulama kapalıyken ağdan güncelleme yoktur.
- Bildirimler kayıtlı menülerden oluşturulur; saatler varsayılan Ankara 08:00 ve 17:00, öğün açılış varsayılan geçişi 12:00. Android bildirim izni gerekir; pil kısıtları ve alarm zamanlaması gecikmeye yol açabilir. Favori bildirimi belirlenen öğün saatinde çalışır, menü kaydı yoksa bildirim gönderilmez.
- Widget aktif öğünün kayıtlı menüsünü gösterir; 30 dakikalık Android periyodu yaklaşık olup cihaz tarafından geciktirilebilir. Widget eklemeden önce uygulamayı açın.
- Sürüm kontrolü GitHub Releases'daki yayımlanmış semantik sürüm etiketini açılışta kontrol eder; ör. v0.3.0. Actions çıktısı tek başına Release sayılmaz. Otomatik APK yüklemez.
- GitHub Actions debug APK'ları farklı anahtarla imzalanabilir. Mevcut uygulama üzerine yükleme reddedilirse uygulamayı kaldırmadan önce özel veri ve ayarlarınızı kaydedin (otomatik taşıma/aktarım yok). Sonraki sürümlerde kalıcı imzalama anahtarı yapılandırılmalıdır. Anahtar veya şifreyi public repoya yüklemeyin.
