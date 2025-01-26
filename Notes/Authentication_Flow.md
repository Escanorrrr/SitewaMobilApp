# Kimlik Doğrulama ve Multi-Tenant Yapı

## Genel Akış

1. Kullanıcı girişi (`/api/auth/login`)
   - Giriş bilgileri:
     ```json
     {
       "siteCode": "BLOK2",
       "username": "mehmet",
       "password": "1234"
     }
     ```

2. Tenant Management DB Kontrolü
   - `siteCode`'a göre ilgili sitenin `connectionString` bilgisi alınır
   - Bu bilgi cache'te yoksa DB'den alınır ve cache'e yazılır
   - Cache süresi: 1-2 saat (Absolute Expiration)

3. Site DB'sine Bağlanma
   - Alınan `connectionString` ile ilgili sitenin DB'sine bağlanılır
   - Kullanıcı bilgileri (`username` ve `password`) kontrol edilir

4. JWT Token Oluşturma
   - Başarılı giriş sonrası JWT token oluşturulur
   - Token içeriği:
     - UserId
     - TenantId (siteId)
     - Role
     - Geçerlilik süresi

5. Sonraki İstekler
   - Her istekte JWT token `Authorization: Bearer` header'ı ile gönderilir
   - Token içindeki `TenantId` kullanılarak:
     1. Cache'ten `connectionString` bilgisi alınır
     2. Cache'te yoksa Tenant Management DB'den alınır
     3. İlgili site DB'sine bağlanılır

## Cache Mekanizması

```csharp
// Örnek cache yapısı
Dictionary<string, string> tenantConnectionStrings = new();

// Cache key formatı
$"tenant_{tenantId}_connection"

// Cache süresi
TimeSpan cacheExpiration = TimeSpan.FromHours(2);
```

## Güvenlik Kontrolleri

1. Site Kodu Kontrolü
   - Geçersiz site kodu için "Böyle bir site yok" hatası
   - Site aktif/pasif durumu kontrolü

2. Kullanıcı Doğrulama
   - Şifre hash kontrolü
   - Hesap aktif/pasif durumu kontrolü

3. Token Güvenliği
   - Token süre kontrolü
   - Token imza doğrulaması
   - TenantId manipülasyon kontrolü

## Middleware Yapısı

```csharp
public class TenantMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;

    public async Task InvokeAsync(HttpContext context)
    {
        // Token'dan TenantId al
        // Cache'ten veya DB'den connectionString al
        // Context'e connectionString bilgisini ekle
        // Sonraki middleware'e devam et
    }
}
```

## Örnek Endpoint Yapısı

```csharp
[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        // 1. Tenant Management DB'den connectionString al
        // 2. Site DB'sine bağlan
        // 3. Kullanıcı doğrula
        // 4. JWT token oluştur
        // 5. Token döndür
    }
}
``` 