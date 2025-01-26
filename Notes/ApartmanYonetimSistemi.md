# Apartman Yönetim Sistemi Dokümantasyonu

## Proje Özeti
Bu proje, apartman yönetimini dijitalleştirmek ve kolaylaştırmak amacıyla geliştirilmiş bir sistemdir.

## Temel Özellikler

### 1. Kullanıcı Yönetimi
- Apartman sakinleri için hesap oluşturma
- Yönetici hesapları
- Rol tabanlı yetkilendirme sistemi

### 2. Aidat Yönetimi
- Aidat ödeme sistemi
- Ödeme geçmişi görüntüleme
- Borç durumu takibi
- Online ödeme entegrasyonu

### 3. Borç/Alacak Takibi
- Yöneticiler tarafından borç tanımlama
- Otomatik aidat borcu oluşturma
- Borç/alacak raporlama

### 4. Duyuru Sistemi
- Apartman sakinlerine duyuru gönderme
- Acil durum bildirimleri
- Toplantı planlaması

### 5. Gider Yönetimi
- Apartman giderlerinin kaydı
- Gider kategorileri
- Fatura takibi
- Bütçe planlama

### 6. Raporlama
- Aylık/yıllık gelir-gider raporları
- Borç/alacak raporları
- Aidat ödeme raporları

## Teknik Detaylar
- .NET Core Web API
- React tabanlı frontend
- SQL Server veritabanı
- JWT tabanlı kimlik doğrulama

## Kullanım Senaryoları

### Apartman Sakini
1. Aidat ödeme
2. Borç görüntüleme
3. Ödeme geçmişi inceleme
4. Duyuruları görüntüleme

### Yönetici
1. Aidat tanımlama
2. Borç ekleme
3. Gider kaydı oluşturma
4. Duyuru yayınlama
5. Raporları görüntüleme

## Geliştirme Süreci
- Her özellik ayrı bir branch'te geliştirilecek
- Değişiklikler düzenli commit'lerle takip edilecek
- Kod değişiklikleri `/notes` klasöründe dokümante edilecek 