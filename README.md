# 📺 İlyasTV iOS - Modern IPTV & Medya Oynatıcı

![iOS](https://img.shields.io/badge/Platform-iOS_16.0+-000000?style=for-the-badge&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Language-Swift_5.9+-F05138?style=for-the-badge&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-007AFF?style=for-the-badge&logo=swift&logoColor=white)
![AVPlayer](https://img.shields.io/badge/Player-AVFoundation_%26_AVKit-FF2D55?style=for-the-badge)

**İlyasTV iOS**, İlyasTV Android uygulamasının tüm özelliklerini birebir içeren; Canlı TV kanalları, VOD sinema filmleri ve diziler için geliştirilmiş, yüksek performanslı, zengin özellikli ve modern bir iOS IPTV oynatıcı uygulamasıdır. Apple tasarım ilkeleri doğrultusunda tamamen **SwiftUI** ve **AVFoundation** kullanılarak geliştirilmiştir.

---

## 🌟 Öne Çıkan Özellikler

### 1. 🔴 Canlı Yayın Kaydı (PVR - Personal Video Recorder)
* **Canlı Kayıt:** Canlı TV yayınlarını izlerken tek tıkla arka planda yerel depolamaya kaydetme (`.ts` / `.mp4`).
* **Canlı REC Paneli:** Oynatıcı ekranında anlık geçen süre (00:00:00) ve kaydedilen toplam dosya boyutu (MB/GB) göstergesi.
* **Kayıt Yönetimi & Çevrimdışı İzleme:** Tamamlanan PVR kayıtları otomatik olarak veritabanına işlenir ve *İndirilenler* sekmesinden internetsiz oynatılabilir.

### 2. 🍿 Binge-Watch Modu (Dizi Maratonu Desteği)
* **Jeneriği Atla (+85sn):** Dizi ve film başlangıçlarında beliren akıllı buton ile introyu tek tıkla atlama.
* **Sonraki Bölüm Uyarısı & Otomatik Geçiş:** Bölümün son 35 saniyesinde çıkan *"Sonraki Bölüm [Hemen Geç]"* kartı ve tek tıkla sıradaki bölüme geçiş.

### 3. 🌐 Çevrimiçi Altyazı Arama & İndirme (SubDL)
* **Dahili Altyazı Arama:** Film veya dizi izlerken **SubDL** API'si üzerinde anlık arama yapabilme.
* **Çoklu Dil Desteği:** Türkçe, İngilizce, Almanca, Fransızca, İspanyolca ve onlarca dil seçeneği.
* **Anında Senkronize Oynatma:** İndirilen `.srt` altyazı dosyası doğrudan video katmanına harici altyazı olarak eklenir.

### 4. 🎬 TMDb Metadata & Film/Dizi Detayları
* **Zengin İçerik Bilgileri:** Film ve diziler için yüksek çözünürlüklü afişler, arka plan görselleri, TMDb / IMDb puanları, yapım yılı, türler ve Türkçe konu özetleri.
* **Detay Kartı:** Oynatıcı içindeki **Bilgi (ℹ️)** butonundan veya içerik ızgarasından detaylı yapım bilgilerine ve YouTube fragman arama bağlantısına anında erişim.

### 5. ⚡ Gelişmiş Oynatıcı Kontrolleri (AVPlayer / AVKit)
* **Jest Kontrolleri:** Sol tarafta dikey kaydırma ile Parlaklık, sağ tarafta Ses kontrolü.
* **Hızlı Sarma:** Ekrana çift dokunarak ±10 saniye sarma.
* **Oynatma Hızı:** 0.5x ile 2.0x arasında esnek hız kontrolü.
* **En-Boy Oranı:** Fit, Fill (16:9, Zoom) geçişleri.
* **Picture in Picture (PiP):** Küçük pencerede arka planda kesintisiz izleme.
* **Ekran Uyanık Kalma:** Video izlerken ekran kararmasını önleme (`isIdleTimerDisabled`).

### 6. 📥 VOD İndirme Yöneticisi & Çevrimdışı İzleme
* Film ve dizi içeriklerini arka planda cihaza indirme (`URLSessionDownloadTask`).
* İnternet bağlantısı olmadan depolamadan direkt oynatma.
* Canlı indirme yüzdesi ve boyut takibi.

### 7. 🌐 Çoklu Playlist & Xtream Codes API Desteği
* M3U / M3U8 URL'si veya Xtream Codes (Sunucu URL, Kullanıcı Adı, Şifre) ile hızlı giriş.
* Dosya Seçici ile cihazdaki yerel `.m3u` dosyalarını yükleme.
* Birden fazla oynatma listesini hafızada tutma ve aralarında geçiş yapma.
* Hesap bitiş tarihi geri sayımı ve üyelik durumu.

### 8. 🛠️ Gelişmiş Son İzlenenler & Geçmiş Yönetimi
* *"En Başa Taşı"*, *"Listeden Sil"*, *"İlerlemeyi Sıfırla (00:00)"*, *"Cihaza İndir"* ve *"Favorilere Ekle"*.

---

## 📱 Ekranlar ve Menü Yapısı

| Ekran | Açıklama |
|---|---|
| **📺 Canlı TV (Live TV)** | Kategorili TV kanalları, son izlenenler ve hızlı kanal değiştirme |
| **🎬 Filmler (Movies)** | Poster ızgarası, TMDb detayları ve VOD oynatma/indirme |
| **🍿 Diziler (Series)** | Sezon ve bölüm hiyerarşisi, Binge-Watch ve otomatik sonraki bölüm |
| **📥 İndirilenler (Downloads)** | İndirilen VOD filmler, dizi bölümleri ve PVR canlı kayıtları |
| **🔍 Arama (Search)** | Canlı arama ve son arama geçmişi |
| **⚙️ Hesap & Ayarlar (Account)** | Playlist yönetimi, Xtream girişi, arabellek ve tema ayarları |

---

## 🏗️ Teknik Mimari

- **Platform:** iOS 16.0+
- **Mimari:** MVVM (Model-View-ViewModel) + Clean Architecture
- **Arayüz:** SwiftUI
- **Medya Oynatıcı:** AVFoundation & AVKit (AVPlayer, AVPlayerViewController, Picture-in-Picture)
- **Depolama:** Persistent Thread-Safe JSON & FileManager Cache
- **Ağ:** Swift Concurrency (async/await), URLSession
- **Paket Yöneticisi:** Swift Package Manager (SPM)

---

## 💻 Kurulum & Çalıştırma (Xcode)

Projeyi Xcode ile açıp doğrudan çalıştırmak için:

```bash
# Proje dizinine gidin
cd ilyastvios

# Xcode ile açın
open Package.swift
```

Xcode açıldığında hedef cihaz olarak dilediğiniz bir iOS Simülatörünü veya gerçek iOS cihazınızı seçip **Run (Cmd + R)** butonuna basmanız yeterlidir.

---

## 📄 Lisans & Yasal Uyarı

- **İlyasTV iOS**, kullanıcının kendi sağladığı yasal M3U / IPTV bağlantılarını ve yayın akışlarını oynatmak üzere geliştirilmiş açık kaynaklı bir medya arayüzüdür.
- Uygulama bünyesinde telif hakkına tabi hiçbir canlı yayın, film veya dizi barındırılmaz ya da sunulmaz.
