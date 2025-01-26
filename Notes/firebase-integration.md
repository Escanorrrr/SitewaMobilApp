# Firebase Entegrasyonu

## Genel Bakış
Bu API, mobil cihazlar için Firebase Cloud Messaging (FCM) entegrasyonu içermektedir. Tüm giriş işlemleri sadece mobil cihazlardan yapılabilir ve her istekte geçerli bir Firebase token gerekmektedir.

## Endpoint'ler

### 1. Login İşlemi
**Endpoint:** `POST /api/auth/login`
**DTO:** `LoginRequest`

**Request Body:**
```json
{
    "siteCode": "string",     // Zorunlu: Site kodu (3-50 karakter)
    "username": "string",     // Zorunlu: Kullanıcı adı (3-100 karakter)
    "password": "string",     // Zorunlu: Şifre (6-50 karakter)
    "firebaseToken": "string", // Zorunlu: Firebase'den alınan token
    "deviceType": "iOS"       // Zorunlu: iOS veya Android
}
```

**Response DTO:** `LoginResponse`

**Başarılı Yanıt (200 OK):**
```json
{
    "token": "string",        // JWT Token
    "user": {
        "id": 1,
        "username": "string",
        "email": "string",
        "firstname": "string",
        "lastname": "string",
        "roleId": 1
    }
}
```

**Hata Durumları:**
- 400 Bad Request: Eksik veya geçersiz veri
- 401 Unauthorized: Hatalı kullanıcı adı/şifre
- 400 Bad Request: Firebase token işlemi başarısız

**İç İşleyiş:**
1. Gelen Firebase token kontrol edilir
2. Eğer token daha önce kaydedilmişse güncellenir
3. Token yoksa yeni kayıt oluşturulur
4. Token işlemi başarısız olursa login işlemi de başarısız olur

### 2. Token Yenileme
**Endpoint:** `POST /api/auth/refresh-token`
**DTO:** `RefreshTokenRequest`

**Authorization:** Bearer Token gerekli

**Request Body:**
```json
{
    "oldToken": "string",     // Zorunlu: Eski Firebase token
    "newToken": "string"      // Zorunlu: Yeni Firebase token
}
```

**Başarılı Yanıt (200 OK):**
```json
{
    "message": "Token başarıyla güncellendi"
}
```

**Hata Durumları:**
- 400 Bad Request: Token'lar boş veya aynı
- 404 Not Found: Eski token bulunamadı
- 401 Unauthorized: Geçersiz JWT token

**İç İşleyiş:**
1. JWT token'dan kullanıcı ve site bilgileri alınır
2. Eski Firebase token veritabanında aranır
3. Token bulunursa yeni token ile güncellenir
4. Token bulunamazsa hata döner

### 3. Duyuru Oluşturma ve Bildirim Gönderme
**Endpoint:** `POST /api/announcements`
**DTO:** `CreateAnnouncementRequest`

**Authorization:** Bearer Token gerekli (CREATE_ANNOUNCEMENT yetkisi olan kullanıcı)

**Request Body:**
```json
{
    "title": "string",       // Zorunlu: Duyuru başlığı (3-150 karakter)
    "content": "string",     // Zorunlu: Duyuru içeriği (min. 10 karakter)
    "type": "GENERAL",       // Zorunlu: GENERAL, MAINTENANCE, MEETING, EMERGENCY, PAYMENT, EVENT, OTHER
    "sendNotification": true // Opsiyonel: Bildirim gönderilsin mi? (varsayılan: false)
}
```

**Başarılı Yanıt (200 OK):**
```json
1  // Oluşturulan duyurunun ID'si
```

**Hata Durumları:**
- 400 Bad Request: Eksik veya geçersiz veri
- 401 Unauthorized: Yetkisiz erişim
- 500 Internal Server Error: Bildirim gönderme hatası

**İç İşleyiş:**
1. Duyuru veritabanına kaydedilir
2. Eğer `sendNotification` true ise:
   - Site koduna göre topic'e bildirim gönderilir
   - Bildirim başlığı duyuru başlığı olur
   - Bildirim içeriği duyuru içeriği olur

**Bildirim Formatı:**
```json
{
    "notification": {
        "title": "[Duyuru Başlığı]",
        "body": "[Duyuru İçeriği]"
    },
    "topic": "[Site Kodu]"
}
```

## Mobil Uygulama İçin Adım Adım Yapılacaklar

### 1. Proje Kurulumu
1. Firebase Console'dan projeyi oluştur
2. Android ve iOS için yapılandırma dosyalarını indir:
   - Android: `google-services.json`
   - iOS: `GoogleService-Info.plist`
3. Flutter paketlerini ekle:
   ```yaml
   dependencies:
     firebase_core: ^latest_version
     firebase_messaging: ^latest_version
   ```

### 2. Uygulama Başlangıcı
1. `main.dart` dosyasında Firebase'i başlat:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     
     // Bildirim izni iste
     await requestNotificationPermission();
     
     runApp(MyApp());
   }
   ```

### 3. Login İşlemi
1. Firebase'den token al:
   ```dart
   String? fcmToken = await FirebaseMessaging.instance.getToken();
   ```

2. Login isteği gönder:
   ```dart
   final response = await loginService.login(
     siteCode: 'AKSES',
     username: 'user',
     password: '123456',
     firebaseToken: fcmToken,
     deviceType: Platform.isIOS ? 'iOS' : 'Android'
   );
   ```

3. Login başarılıysa:
   ```dart
   if (response.success) {
     // JWT token'ı kaydet
     await storage.write('jwt_token', response.token);
     
     // Site koduna abone ol
     String siteCode = 'AKSES'; // JWT'den veya response'dan al
     await FirebaseMessaging.instance.subscribeToTopic(siteCode);
   }
   ```

### 4. Bildirim Dinleme
1. Uygulama açıkken:
   ```dart
   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
     // Yerel bildirim göster
     showLocalNotification(
       title: message.notification?.title ?? '',
       body: message.notification?.body ?? ''
     );
   });
   ```

2. Uygulama kapalıyken:
   ```dart
   // main.dart'ta tanımla
   Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
     // Bildirim otomatik gösterilecek
   }

   // Ve kaydet
   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
   ```

### 5. Token Yenileme
```dart
FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) async {
  // Eski token'ı storage'dan al
  String? oldToken = await storage.read('firebase_token');
  
  // Backend'e bildir
  await authService.refreshToken(
    oldToken: oldToken,
    newToken: newToken
  );
  
  // Yeni token'ı kaydet
  await storage.write('firebase_token', newToken);
});
```

### 6. Logout İşlemi
```dart
Future<void> logout() async {
  // Site kodunu al
  String? siteCode = await storage.read('site_code');
  
  if (siteCode != null) {
    // Topic'ten çık
    await FirebaseMessaging.instance.unsubscribeFromTopic(siteCode);
  }
  
  // Storage'ı temizle
  await storage.deleteAll();
}
```

### Önemli Noktalar
1. **Bildirimler Nasıl Gelir?**
   - Duyuru oluşturulduğunda backend, site koduna sahip topic'e bildirim gönderir
   - O site koduna abone olan tüm cihazlar bildirimi alır
   - Bildirim, title ve body içerir

2. **Topic Mantığı**
   - Her site için bir topic vardır (örn: "AKSES" topic'i)
   - Kullanıcı login olduğunda o sitenin topic'ine abone olur
   - Logout olduğunda topic'ten çıkar
   - Bu sayede sadece login olduğu sitenin bildirimlerini alır

3. **Dikkat Edilmesi Gerekenler**
   - Login olmadan önce Firebase token almayı unutma
   - Login sonrası topic'e abone olmayı unutma
   - Logout'ta topic'ten çıkmayı unutma
   - Token yenilendiğinde backend'e bildirmeyi unutma

## Veritabanı Yapısı

### UserTokens Tablosu
- UserId (int): Kullanıcı ID
- FirebaseToken (string): Firebase token
- DeviceType (enum): iOS/Android
- CreatedAt (datetime): Oluşturma tarihi
- UpdatedAt (datetime): Güncelleme tarihi

### Announcements Tablosu
- Id (int): Duyuru ID
- Title (string): Başlık
- Content (string): İçerik
- Type (enum): Duyuru tipi
- CreatedAt (datetime): Oluşturma tarihi
- CreatedBy (int): Oluşturan kullanıcı ID
- NotificationSent (bool): Bildirim gönderildi mi
- NotificationCount (int): Kaç kişiye gönderildi

## Topic Yönetimi

### Genel Bakış
Backend sadece topic'e bildirim gönderir, topic'lere subscribe olma/olmama işlemleri tamamen Flutter uygulamasının sorumluluğundadır. Her site kendi topic'ine sahiptir ve o sitenin kullanıcıları ilgili topic'e abone olmalıdır.

### Topic Yapısı
- Her site için bir topic vardır
- Topic adı site kodu ile aynıdır (örn: "AKSES", "SITE1" vb.)
- Bir kullanıcı birden fazla site'nin topic'ine abone olabilir

### Topic İşlemleri

1. **Login Sonrası Topic Aboneliği**
   ```dart
   Future<void> handleLoginSuccess(LoginResponse response) async {
     // 1. JWT Token'ı Sakla
     await storage.write(key: 'jwt_token', value: response.jwtToken);
     
     // 2. Firebase Token'ı Sakla (yenileme için gerekli)
     String? firebaseToken = await FirebaseMessaging.instance.getToken();
     await storage.write(key: 'firebase_token', value: firebaseToken);
     
     // 3. Site Kodunu JWT'den Çıkar ve Sakla
     final siteCode = extractSiteCodeFromJWT(response.jwtToken);
     await storage.write(key: 'site_code', value: siteCode);
     
     // 4. Topic'e Abone Ol
     await FirebaseMessaging.instance.subscribeToTopic(siteCode);
   }
   ```

2. **Logout Sırasında Topic'ten Çıkma**
   ```dart
   Future<void> handleLogout() async {
     // Mevcut site kodunu al
     final siteCode = await storage.read(key: 'site_code');
     if (siteCode != null) {
       // Topic'ten unsubscribe ol
       await FirebaseMessaging.instance.unsubscribeFromTopic(siteCode);
     }
     
     // Token ve site bilgilerini temizle
     await storage.deleteAll();
   }
   ```

3. **Çoklu Site Desteği**
   ```dart
   class TopicManager {
     final _subscribedSites = <String>{};
     
     // Yeni bir siteye giriş yapıldığında
     Future<void> addSite(String siteCode) async {
       if (!_subscribedSites.contains(siteCode)) {
         await FirebaseMessaging.instance.subscribeToTopic(siteCode);
         _subscribedSites.add(siteCode);
         await _saveSites(); // Locale kaydet
       }
     }
     
     // Bir siteden çıkış yapıldığında
     Future<void> removeSite(String siteCode) async {
       if (_subscribedSites.contains(siteCode)) {
         await FirebaseMessaging.instance.unsubscribeFromTopic(siteCode);
         _subscribedSites.remove(siteCode);
         await _saveSites(); // Locale kaydet
       }
     }
     
     // Uygulama açılışında topic'leri yeniden yükle
     Future<void> restoreTopics() async {
       final sites = await _loadSites(); // Locale'den oku
       for (final site in sites) {
         await FirebaseMessaging.instance.subscribeToTopic(site);
       }
     }
   }
   ```

### Önemli Senaryolar

1. **İlk Login**
   - Firebase token al
   - Login isteği gönder
   - Başarılı yanıt sonrası site topic'ine subscribe ol
   - Site kodunu locale kaydet

2. **Token Yenileme**
   - Yeni token alındığında backend'e bildir
   - Topic abonelikleri otomatik taşınır (Firebase tarafından)

3. **Logout**
   - Site topic'inden unsubscribe ol
   - Locale'deki site bilgisini temizle
   - JWT token'ı temizle

4. **Uygulama Yeniden Açıldığında**
   - Locale'den site kodunu kontrol et
   - Eğer varsa ve JWT token geçerliyse topic'e yeniden subscribe ol

5. **Çoklu Site Senaryosu**
   - Her başarılı login'de yeni site topic'ine subscribe ol
   - Logout'ta sadece çıkış yapılan sitenin topic'inden unsubscribe ol
   - Diğer site aboneliklerini koru

### Hata Durumları

1. **Topic Subscribe Hatası**
   ```dart
   try {
     await FirebaseMessaging.instance.subscribeToTopic(siteCode);
   } catch (e) {
     // Kullanıcıya bildir ve tekrar deneme seçeneği sun
     showRetryDialog('Topic aboneliği başarısız oldu. Tekrar denemek ister misiniz?');
   }
   ```

2. **Token Yenileme Hatası**
   ```dart
   FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
     try {
       await refreshToken(oldToken, newToken);
     } catch (e) {
       // Belirli aralıklarla tekrar dene
       await retryWithExponentialBackoff(() => refreshToken(oldToken, newToken));
     }
   });
   ```

## JWT ve Topic Yönetimi

### 1. Login Sonrası İşlemler
```dart
Future<void> handleLoginSuccess(LoginResponse response) async {
  // 1. JWT Token'ı Sakla
  await storage.write(key: 'jwt_token', value: response.jwtToken);
  
  // 2. Firebase Token'ı Sakla (yenileme için gerekli)
  String? firebaseToken = await FirebaseMessaging.instance.getToken();
  await storage.write(key: 'firebase_token', value: firebaseToken);
  
  // 3. Site Kodunu JWT'den Çıkar ve Sakla
  final siteCode = extractSiteCodeFromJWT(response.jwtToken);
  await storage.write(key: 'site_code', value: siteCode);
  
  // 4. Topic'e Abone Ol
  await FirebaseMessaging.instance.subscribeToTopic(siteCode);
}
```

### 2. API İsteklerinde JWT Kullanımı
```dart
class ApiService {
  Future<String?> getJwtToken() async {
    return await storage.read(key: 'jwt_token');
  }

  // Her API isteğinde JWT'yi ekle
  Future<dynamic> get(String endpoint) async {
    final jwtToken = await getJwtToken();
    final response = await http.get(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    return handleResponse(response);
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    final jwtToken = await getJwtToken();
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return handleResponse(response);
  }
}
```

### 3. Firebase Token Yenileme
```dart
FirebaseMessaging.instance.onTokenRefresh.listen((String newFirebaseToken) async {
  // Eski Firebase Token'ı storage'dan al
  String? oldFirebaseToken = await storage.read('firebase_token');
  
  // Backend'e bildir
  await authService.refreshFirebaseToken(
    oldToken: oldFirebaseToken,
    newToken: newFirebaseToken
  );
  
  // Yeni Firebase Token'ı kaydet
  await storage.write('firebase_token', newFirebaseToken);
});
```

### Önemli Noktalar

1. **JWT Yönetimi**
   - JWT her API isteğinde `Authorization: Bearer` header'ı ile gönderilmeli
   - JWT'nin süresi kontrol edilmeli
   - JWT güvenli bir şekilde saklanmalı (FlutterSecureStorage)

2. **Firebase Token Yönetimi**
   - Firebase Token login sırasında backend'e gönderilmeli
   - Firebase Token değiştiğinde backend'e bildirilmeli
   - Firebase Token güvenli şekilde saklanmalı

3. **Güvenlik**
   - JWT ve Firebase Token'ları secure storage'da sakla
   - Logout sırasında tüm token'ları temizle

## Bildirim Akışı ve İşleme Süreci

### 1. Bildirim Gönderme Akışı


1. Backend'den Firebase'e istek gider
   - Duyuru başlığı
   - Duyuru içeriği
   - Hedef topic (site kodu)

2. Firebase, topic'e kayıtlı tüm cihazlara bildirim gönderir
   - Topic'e subscribe olan tüm cihazlar bildirimi alır
   - Her cihaz kendi durumuna göre bildirimi işler

3. Mobil Cihazlar bildirimi alır
   - Uygulama açıksa: Manuel gösterim yapılır
   - Uygulama kapalıysa: Sistem otomatik gösterir

### 2. Bildirim Türleri ve İşleme

#### Foreground (Uygulama Açıkken)
```dart
// main.dart veya bir service dosyasında
void initializeForegroundHandler() {
  // Uygulama açıkken gelen bildirimleri dinle
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Bildirim verilerini al
    final notification = message.notification;
    final data = message.data;

    // Yerel bildirim göster
    if (notification != null) {
      FlutterLocalNotificationsPlugin().show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Yüksek Önemli Bildirimler',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: IOSNotificationDetails(),
        ),
        payload: jsonEncode(data), // Tıklama için veri sakla
      );
    }
  });

  // Bildirime tıklanınca
  FlutterLocalNotificationsPlugin().initialize(
    InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: IOSInitializationSettings(),
    ),
    onSelectNotification: (payload) async {
      if (payload != null) {
        final data = jsonDecode(payload);
        // Bildirime tıklanınca yapılacak işlemler
        handleNotificationTap(data);
      }
    },
  );
}
```

#### Background (Uygulama Arkaplanda/Kapalı)
```dart
// main.dart
// Arkaplanda çalışacak handler'ı tanımla
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase başlatılmamışsa başlat
  await Firebase.initializeApp();

  // Bildirimi göster (sistem otomatik gösterecek)
  print("Arkaplanda bildirim alındı: ${message.notification?.title}");
}

void main() async {
  // Background handler'ı kaydet
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // ... diğer başlangıç kodları
}
```

#### Bildirime Tıklama İşlemi
```dart
void handleNotificationTap(Map<String, dynamic> data) {
  // Bildirim tipine göre yönlendirme yap
  switch (data['type']) {
    case 'ANNOUNCEMENT':
      // Duyuru detayına git
      Navigator.pushNamed(
        context,
        '/announcement-detail',
        arguments: {'id': data['announcementId']},
      );
      break;
    case 'MAINTENANCE':
      // Bakım sayfasına git
      Navigator.pushNamed(context, '/maintenance');
      break;
    // ... diğer tipler
  }
}
```

### 3. Bildirim Kanalları (Android)
```dart
void setupNotificationChannels() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Android için kanal oluştur
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Yüksek Önemli Bildirimler',
    importance: Importance.high,
  );

  // Kanalı sisteme kaydet
  await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
}
```

### 4. iOS İzinleri
```dart
void requestIOSPermissions() async {
  // iOS için bildirim izinlerini iste
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
}
```

### Bildirim Veri Yapısı

1. **Backend'den Gönderilen**
```json
{
    "notification": {
        "title": "Yeni Duyuru",
        "body": "Duyuru içeriği"
    },
    "data": {
        "type": "ANNOUNCEMENT",
        "announcementId": "123",
        "priority": "high"
    },
    "topic": "AKSES"
}
```

2. **Flutter'da Alınan (RemoteMessage)**
```dart
RemoteMessage(
    notification: RemoteNotification(
        title: "Yeni Duyuru",
        body: "Duyuru içeriği"
    ),
    data: {
        "type": "ANNOUNCEMENT",
        "announcementId": "123",
        "priority": "high"
    }
)
```

### Önemli Noktalar

1. **Bildirim İşleme Durumları**
   - Uygulama Açık (Foreground): Manuel gösterim gerekir
   - Uygulama Arkaplanda: Sistem otomatik gösterir
   - Uygulama Kapalı: Sistem otomatik gösterir

2. **Bildirim Tipleri**
   - Notification: Başlık ve içerik (görsel kısım)
   - Data: Özel veriler (yönlendirme, ID'ler vb.)

3. **Platform Farkları**
   - Android: Notification Channel gerekli
   - iOS: Bildirim izinleri gerekli

4. **Dikkat Edilmesi Gerekenler**
   - Background handler'ı main.dart'ta tanımla
   - iOS için gerekli izinleri al
   - Android için kanal oluştur
   - Bildirim tıklama işlemlerini doğru yönet

[kalan içerik aynı kalacak...] 