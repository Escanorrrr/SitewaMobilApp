# Multi-Tenant Veritabanı Bağlantı Yapısı

## Genel Bakış

Sistemimiz iki farklı veritabanı seviyesinde çalışır:
1. **Tenant Management DB**: Tüm sitelerin bilgilerini ve connection string'lerini tutan merkezi veritabanı
2. **Site DB'leri**: Her sitenin kendi verileri için ayrı veritabanları

## Bağlantı Akışı

1. Kullanıcı `auth/login` endpoint'ine `siteCode` ile birlikte istek atar
2. `AuthController` bu isteği alır ve `ISiteDbContextFactory.CreateDbContextAsync(siteCode)` metodunu çağırır
3. Factory, `ITenantService` üzerinden connection string'i alır
4. Connection string ile yeni bir `SiteDbContext` oluşturulur ve kullanılır

## Kod Örnekleri

### 1. AuthController'da Kullanım
```csharp
[HttpPost("login")]
public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
{
    // SiteDbContextFactory üzerinden ilgili site için DbContext oluşturulur
    var dbContext = await _contextFactory.CreateDbContextAsync(request.SiteCode);
    
    // Oluşturulan DbContext ile veritabanına sorgu yapılır
    var user = await dbContext.Users
        .FirstOrDefaultAsync(u => u.Username == request.Username);
    // ...
}
```

### 2. SiteDbContextFactory'de DbContext Oluşturma
```csharp
public async Task<SiteDbContext> CreateDbContextAsync(string siteCode)
{
    // TenantService üzerinden connection string alınır
    var connectionString = await _tenantService.GetConnectionStringAsync(siteCode);
    if (connectionString == null)
    {
        throw new Exception($"Site bulunamadı veya aktif değil: {siteCode}");
    }

    // Alınan connection string ile DbContext options oluşturulur
    var optionsBuilder = new DbContextOptionsBuilder<SiteDbContext>();
    optionsBuilder.UseSqlServer(connectionString);

    // Yeni bir DbContext instance'ı oluşturulur ve döndürülür
    return new SiteDbContext(optionsBuilder.Options);
}
```

### 3. TenantService'de Connection String Yönetimi
```csharp
public async Task<string?> GetConnectionStringAsync(string siteCode)
{
    // Önce cache'e bakılır
    var cachedConnectionString = await _cache.GetAsync(siteCode);
    if (cachedConnectionString != null)
    {
        return cachedConnectionString;
    }

    // Cache'de yoksa Tenant Management DB'den alınır
    var tenant = await _context.Tenants
        .FirstOrDefaultAsync(t => t.SiteCode == siteCode);

    if (tenant == null)
    {
        return null;
    }

    // Bulunan connection string cache'e eklenir ve döndürülür
    await _cache.SetAsync(siteCode, tenant.ConnectionString);
    return tenant.ConnectionString;
}
```

## Önemli Noktalar

1. **Dependency Injection**: Tüm bileşenler DI container üzerinden yönetilir
   ```csharp
   builder.Services.AddScoped<ISiteDbContextFactory, SiteDbContextFactory>();
   builder.Services.AddScoped<ITenantService, TenantService>();
   builder.Services.AddSingleton<ITenantConnectionCache, TenantConnectionCache>();
   ```

2. **Connection String Cache**: Performans için connection string'ler cache'lenir
   - `AbsoluteExpirationHours`: 2 saat sonra cache'den silinir
   - `SlidingExpirationMinutes`: 30 dakika kullanılmazsa cache'den silinir

3. **Scoped Lifetime**: Her request için yeni bir DbContext oluşturulur
   - Bu sayede her request thread-safe çalışır
   - Her request kendi connection'ını yönetir

4. **Error Handling**: Connection string bulunamazsa veya geçersizse uygun hata mesajları döndürülür

## Örnek Senaryo

1. Kullanıcı "AKSES" site kodu ile login olmak istiyor
2. `AuthController` bu isteği alıyor
3. `SiteDbContextFactory` üzerinden DbContext isteniyor
4. `TenantService` önce cache'e bakıyor
5. Cache'de yoksa Tenant Management DB'den "AKSES" sitesinin connection string'i alınıyor
6. Bu connection string ile yeni bir `SiteDbContext` oluşturuluyor
7. `AuthController` bu context'i kullanarak kullanıcı bilgilerini sorgulayabiliyor 