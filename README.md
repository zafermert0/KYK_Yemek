# YurtMenü — Ankara KYK

0.1.0: yerel Android/Flutter başlangıç sürümü. Flutter projesinin Android ve iOS iskeleti GitHub Actions'ta oluşturulur; iOS derlemesi henüz yapılandırılmadı. Web uygulaması ve sunucu yok.

## Kurulum yapmadan APK oluştur
1. GitHub'da `yurtmenu` isimli bir depo oluştur (kişisel bilgi eklemek gerekmez; public açık kaynak için, private kişisel kullanım için). `Add a README` seçeneğini aç.
2. ZIP'i çıkar ve kök dizindeki `main.dart`, `README.md`, `LICENSE` dosyalarını deponun **Add file → Upload files** bölümüne yükle. README çakışırsa mevcut README'yi bırakabilirsin.
3. **Add file → Create new file** seç; dosya adı `.github/workflows/android.yml` olsun. Pakette aynı konumdaki YAML içeriğini kopyala, commit et. Windows'ta `.github` klasörü görünmüyorsa ayrı verilen YAML dosyasını kullan.
4. **Actions → Android APK** akışını aç. Otomatik çalışmadıysa **Run workflow** ile başlat.
5. Başarılı çalışmanın **Artifacts → YurtMenu-Android** bölümünden indir, ZIP'i aç. APK'yı kendi Android cihazında, kendi kaynağından geldiğini doğruladıktan sonra normal Android yükleme ekranından kur. Cihaz/ebeveyn tarafından konulan güvenlik kısıtlarını değiştirme veya atlatma.

Debug imza anahtarı her bulut çalıştırmasında farklı olabileceğinden sonraki sürümlerde doğrudan güncelleme başarısız olabilir. Sabit imzalama sonraki aşama; kaldırma işlemi yerel menüleri siler. İleride kalıcı anahtar çözümü eklenmeli. GitHub Actions ücretsiz kota ve hesap koşullarına tabidir.

## Menüler
Sabit başlangıç kayıtları 13–15 Kasım 2026. Kaynaklar (resmî GSB değil): https://yurtmenu.net/ankara , https://yurtmenu.net/ , https://kykmenu.com.tr/menu/ankara . 15 Kasım kaydı kısmi olabilir. Gerçek menü yurt duyurusuyla değişebilir. Otomatik veri erişim izni doğrulanmadığından ağ isteği veya scraping yok. Ayarlar > Menü verisi ekle ile kendi JSON kayıtlarını yapıştır; kayıtlar cihazda saklanır. Örnek:

```json
{"2026-11-16":{"breakfast":["Omlet"],"dinner":["Çorba"]}}
```

Bu örnek gerçek menü değildir. Kayıtsız günler boş gösterilir. Uygulama kodu MIT; üçüncü taraf yemek verilerine ayrı kullanım koşulları uygulanabilir.

## Durum
Telefon/tablet düzeni, tarih şeridi, takvim, iki tema, yerel veri ekleme. Bildirim, ana ekran widget'ı ve canlı veri henüz yok. Bu ortamda Flutter SDK olmadığı için APK derleme/emülatör testi yapılmadı; workflow ilk derlemeyi yapar.
