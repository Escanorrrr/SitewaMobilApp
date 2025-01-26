# Cache Mekanizması: TenantConnectionCache

## Genel Bakış

`TenantConnectionCache` sınıfı, site (tenant) bağlantı dizelerini önbellekte (memory cache) tutmak için kullanılır. Bu sayede her istekte veritabanına gitmek yerine, bağlantı dizelerini RAM'de saklayarak performansı artırır.

## Nasıl Çalışır?

### 1. Memory Cache Kullanımı

```csharp
public class TenantConnectionCache : ITenantConnectionCache
{
    private readonly IMemoryCache _cache;
    private readonly CacheSettings _settings;

    public TenantConnectionCache(IMemoryCache cache, IOptions<CacheSettings> settings)
    {
        _cache = cache;
        _settings = settings.Value;
    }
}
```

- `IMemoryCache`: .NET'in built-in memory cache sistemi
- `CacheSettings`: Cache'in yaşam süresini belirleyen ayarlar

### 2. Veri Saklama ve Okuma

```csharp
// Veri Okuma
public Task<string?> GetAsync(string siteCode)
{
    // "tenant_connection_AKSES101" gibi bir key ile cache'den okur
    _cache.TryGetValue<string>(GetCacheKey(siteCode), out var connectionString);
    return Task.FromResult(connectionString);
}

// Veri Yazma
public Task SetAsync(string siteCode, string connectionString)
{
    var cacheOptions = new MemoryCacheEntryOptions()
        .SetAbsoluteExpiration(TimeSpan.FromHours(_settings.AbsoluteExpirationHours))
        .SetSlidingExpiration(TimeSpan.FromMinutes(_settings.SlidingExpirationMinutes));

    _cache.Set(GetCacheKey(siteCode), connectionString, cacheOptions);
    return Task.CompletedTask;
}
```

### 3. Cache Ayarları

```json
// appsettings.json
{
  "CacheSettings": {
    "AbsoluteExpirationHours": 2,     // 2 saat sonra kesin silinir
    "SlidingExpirationMinutes": 30    // 30 dakika kullanılmazsa silinir
  }
}
```

## Kullanım Senaryosu

1. Kullanıcı login isteği yapar (`AKSES101` site kodu ile)
2. `TenantService` önce cache'e bakar:

```csharp
public async Task<string?> GetConnectionStringAsync(string siteCode)
{
    // 1. Önce cache'e bak
    var cachedConnectionString = await _cache.GetAsync(siteCode);
    if (cachedConnectionString != null)
    {
        return cachedConnectionString; // Cache'de varsa direkt döndür
    }

    // 2. Cache'de yoksa DB'den al
    var tenant = await _context.Tenants
        .FirstOrDefaultAsync(t => t.SiteCode == siteCode);

    if (tenant == null)
    {
        return null;
    }

    // 3. DB'den alınan veriyi cache'e yaz
    await _cache.SetAsync(siteCode, tenant.ConnectionString);
    return tenant.ConnectionString;
}
```

## Cache'in Avantajları

1. **Performans**
   - Veritabanı sorgusu sayısı azalır
   - Yanıt süreleri kısalır
   - Sunucu kaynakları daha verimli kullanılır

2. **Yük Azaltma**
   - Veritabanı üzerindeki yük azalır
   - Ağ trafiği azalır

3. **Maliyet**
   - Daha az veritabanı bağlantısı
   - Daha az kaynak kullanımı
   - Daha düşük işletim maliyeti

## Cache Süresi Mantığı

1. **Absolute Expiration (2 saat)**
   - Cache'deki veri en fazla 2 saat tutulur
   - 2 saat sonra kesinlikle silinir
   - Veri güncelliği için güvenlik önlemi

2. **Sliding Expiration (30 dakika)**
   - Veri 30 dakika kullanılmazsa silinir
   - Her kullanımda süre yenilenir
   - Gereksiz veriyi cache'de tutmamak için

## Örnek Akış

```plaintext
1. İstek: AKSES101 sitesi için login
   ↓
2. Cache Kontrolü: tenant_connection_AKSES101
   ├── Varsa: Direkt kullan
   └── Yoksa: DB'den al ve cache'e yaz
   ↓
3. Bağlantı dizesi ile işleme devam et
```

## Cache Temizleme

```csharp
public Task RemoveAsync(string siteCode)
{
    _cache.Remove(GetCacheKey(siteCode));
    return Task.CompletedTask;
}
```

Bu metot şu durumlarda kullanılır:
- Site bilgileri güncellendiğinde
- Site silindiğinde
- Cache'deki veri geçersiz olduğunda

## Memory Cache vs Distributed Cache

Şu anki implementasyon Memory Cache kullanıyor. Yani:
- Veriler sunucunun RAM'inde tutuluyor
- Sunucu yeniden başlatıldığında cache temizleniyor
- Çoklu sunucu (load balancer) durumunda her sunucu kendi cache'ini tutuyor

İleride Redis gibi distributed cache'e geçiş yapılabilir:
- Veriler merkezi bir cache sunucusunda tutulur
- Sunucu yeniden başlatmalarından etkilenmez
- Tüm sunucular aynı cache'i kullanır 

## Projede Cache'lenebilecek Diğer Veriler

### 1. Kullanıcı Rolleri ve İzinleri
```csharp
public class UserPermissionCache
{
    private const string KEY_PATTERN = "user_permissions_{0}_{1}"; // siteCode_userId
    private readonly ISiteDbContextFactory _contextFactory;

    public UserPermissionCache(ISiteDbContextFactory contextFactory)
    {
        _contextFactory = contextFactory;
    }

    public async Task<List<Permission>> GetUserPermissionsAsync(string siteCode, int userId)
    {
        var key = string.Format(KEY_PATTERN, siteCode, userId);
        
        if (!_cache.TryGetValue(key, out List<Permission> permissions))
        {
            // Her site için kendi DB'sine bağlanıyoruz
            using var dbContext = await _contextFactory.CreateDbContextAsync(siteCode);
            
            permissions = await dbContext.UserPermissions
                .Where(up => up.UserId == userId)
                .Include(up => up.Permission)
                .Select(up => up.Permission)
                .ToListAsync();

            _cache.Set(key, permissions, TimeSpan.FromHours(1));
        }
        return permissions;
    }

    public async Task RemoveUserPermissionsAsync(string siteCode, int userId)
    {
        var key = string.Format(KEY_PATTERN, siteCode, userId);
        _cache.Remove(key);
    }

    // Bir sitedeki tüm kullanıcıların izinlerini temizle
    public async Task RemoveAllSitePermissionsAsync(string siteCode)
    {
        // Pattern matching ile site koduna ait tüm cache'leri temizle
        var pattern = $"user_permissions_{siteCode}_*";
        // Pattern'e uyan tüm keyleri bul ve sil
        // Not: IMemoryCache pattern matching desteklemez
        // Redis gibi distributed cache kullanılması önerilir
    }
}
```
- Her site için ayrı cache key kullanılır (`user_permissions_AKSES101_123`)
- Her istek kendi site DB'sine bağlanır
- Cache temizleme işlemi site bazlı yapılabilir
- Pattern matching için Redis gibi distributed cache önerilir

### 2. Site Ayarları
```csharp
public class SiteSettingsCache
{
    private const string KEY_PATTERN = "site_settings_{0}"; // siteCode

    public async Task<SiteSettings> GetSiteSettingsAsync(string siteCode)
    {
        var key = string.Format(KEY_PATTERN, siteCode);
        if (!_cache.TryGetValue(key, out SiteSettings settings))
        {
            settings = await _dbContext.SiteSettings
                .FirstOrDefaultAsync(s => s.SiteCode == siteCode);

            _cache.Set(key, settings, TimeSpan.FromHours(12));
        }
        return settings;
    }
}
```
- Logo, tema, iletişim bilgileri gibi site ayarları
- Nadiren değişir, uzun süre cache'de tutulabilir
- Site yöneticisi güncellediğinde cache temizlenir

### 3. Duyurular ve Bildirimler
```csharp
public class AnnouncementCache
{
    private const string KEY_PATTERN = "site_announcements_{0}"; // siteCode

    public async Task<List<Announcement>> GetActiveAnnouncementsAsync(string siteCode)
    {
        var key = string.Format(KEY_PATTERN, siteCode);
        if (!_cache.TryGetValue(key, out List<Announcement> announcements))
        {
            announcements = await _dbContext.Announcements
                .Where(a => a.SiteCode == siteCode && a.IsActive)
                .OrderByDescending(a => a.CreatedAt)
                .Take(10)
                .ToListAsync();

            _cache.Set(key, announcements, TimeSpan.FromMinutes(15));
        }
        return announcements;
    }
}
```
- Aktif duyurular sık sık görüntülenir
- Kısa süreli cache kullanılabilir (15-30 dakika)
- Yeni duyuru eklendiğinde cache temizlenir

### 4. Aidat Tarifeleri
```csharp
public class DuesRateCache
{
    private const string KEY_PATTERN = "dues_rates_{0}"; // siteCode

    public async Task<List<DuesRate>> GetCurrentDuesRatesAsync(string siteCode)
    {
        var key = string.Format(KEY_PATTERN, siteCode);
        if (!_cache.TryGetValue(key, out List<DuesRate> rates))
        {
            rates = await _dbContext.DuesRates
                .Where(d => d.SiteCode == siteCode && d.IsActive)
                .ToListAsync();

            _cache.Set(key, rates, TimeSpan.FromHours(24));
        }
        return rates;
    }
}
```
- Aidat tarifeleri nadiren değişir
- Uzun süreli cache kullanılabilir (24 saat)
- Tarife güncellendiğinde cache temizlenir

### 5. Kullanıcı Profil Bilgileri
```csharp
public class UserProfileCache
{
    private const string KEY_PATTERN = "user_profile_{0}_{1}"; // siteCode_userId

    public async Task<UserProfile> GetUserProfileAsync(string siteCode, int userId)
    {
        var key = string.Format(KEY_PATTERN, siteCode, userId);
        if (!_cache.TryGetValue(key, out UserProfile profile))
        {
            profile = await _dbContext.UserProfiles
                .Include(u => u.Apartment)
                .FirstOrDefaultAsync(u => u.SiteCode == siteCode && u.UserId == userId);

            _cache.Set(key, profile, TimeSpan.FromHours(6));
        }
        return profile;
    }
}
```
- Kullanıcı profil bilgileri sık görüntülenir
- Orta süreli cache kullanılabilir (6 saat)
- Profil güncellendiğinde cache temizlenir

### 6. Referans Verileri
```csharp
public class ReferenceDataCache
{
    public async Task<List<City>> GetCitiesAsync()
    {
        const string key = "reference_cities";
        if (!_cache.TryGetValue(key, out List<City> cities))
        {
            cities = await _dbContext.Cities.ToListAsync();
            _cache.Set(key, cities, TimeSpan.FromDays(7));
        }
        return cities;
    }
}
```
- İl/ilçe, meslek, banka listesi gibi referans veriler
- Çok nadiren değişir, uzun süre cache'de tutulabilir
- Manuel olarak güncellendiğinde cache temizlenir

## Cache Stratejisi Önerileri

1. **Değişim Sıklığına Göre Cache Süresi**
   - Sık değişen: 15-30 dakika
   - Orta sıklıkta: 1-6 saat
   - Nadir değişen: 12-24 saat
   - Statik veriler: 7 gün veya daha fazla

2. **Memory Kullanımı**
   - Küçük veriler için memory cache
   - Büyük veriler için distributed cache (Redis)
   - Cache boyutu limiti belirleme

3. **Cache Invalidation (Temizleme)**
   - Veri güncellendiğinde ilgili cache'i temizle
   - Toplu güncelleme durumunda pattern ile temizle
   - Düzenli cache temizliği için background job 