# Asenkron Programlama: Neden ve Nasıl?

## Senkron vs Asenkron

### Senkron (Normal) Programlama
```csharp
// Senkron metot örneği
public string GetConnectionString(string siteCode)
{
    // Bu işlem veritabanından okuma yapana kadar thread bloklanır
    var tenant = _context.Tenants
        .FirstOrDefault(t => t.SiteCode == siteCode);

    if (tenant == null)
        return null;

    return tenant.ConnectionString;
}
```

**Dezavantajları:**
1. Her istek bir thread'i bloklar
2. Thread havuzu tükenebilir
3. Sunucu daha az isteğe cevap verebilir
4. Yüksek bellek kullanımı

### Asenkron Programlama
```csharp
// Asenkron metot örneği
public async Task<string?> GetConnectionStringAsync(string siteCode)
{
    // Thread bloklanmaz, başka istekleri işleyebilir
    var tenant = await _context.Tenants
        .FirstOrDefaultAsync(t => t.SiteCode == siteCode);

    if (tenant == null)
        return null;

    return tenant.ConnectionString;
}
```

**Avantajları:**
1. Thread'ler bloklanmaz
2. Aynı anda daha fazla istek işlenebilir
3. Daha iyi kaynak kullanımı
4. Daha iyi ölçeklenebilirlik

## Login İsteği Örneği

### Senkron Versiyon
```csharp
[HttpPost("login")]
public ActionResult<LoginResponse> Login(LoginRequest request)
{
    // 1. Connection string al (DB'yi bloklar)
    var connectionString = _tenantService.GetConnectionString(request.SiteCode);
    
    // 2. Site DB'sine bağlan (Yeni DB bağlantısını bloklar)
    using var dbContext = _contextFactory.CreateDbContext(connectionString);
    
    // 3. Kullanıcıyı bul (Site DB'sini bloklar)
    var user = dbContext.Users
        .FirstOrDefault(u => u.Username == request.Username);

    // ... devamı ...
}
```

**Ne Olur?**
1. Her adımda thread bloklanır
2. Diğer kullanıcılar sırada bekler
3. Yoğun trafikte sunucu yavaşlar
4. Timeout hataları oluşabilir

### Asenkron Versiyon
```csharp
[HttpPost("login")]
public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
{
    // 1. Connection string al (Thread serbest kalır)
    var connectionString = await _tenantService.GetConnectionStringAsync(request.SiteCode);
    
    // 2. Site DB'sine bağlan (Thread serbest kalır)
    var dbContext = await _contextFactory.CreateDbContextAsync(connectionString);
    
    // 3. Kullanıcıyı bul (Thread serbest kalır)
    var user = await dbContext.Users
        .FirstOrDefaultAsync(u => u.Username == request.Username);

    // ... devamı ...
}
```

**Ne Olur?**
1. Thread her await'te serbest kalır
2. Diğer istekler paralel işlenir
3. Sunucu daha fazla yük kaldırabilir
4. Daha iyi performans

## Gerçek Dünya Örneği

Bir restoran düşünelim:
- **Senkron (Normal) Garson:**
  - Bir masanın siparişini alır
  - Mutfağa gider ve yemek hazır olana kadar bekler
  - Yemeği alıp masaya getirir
  - Ancak ondan sonra yeni bir masaya bakabilir

- **Asenkron Garson:**
  - Bir masanın siparişini alır
  - Mutfağa bırakır ve hemen diğer masalara bakar
  - Mutfak "yemek hazır" dediğinde gidip alır
  - Bu sırada sürekli başka masalara da hizmet verebilir

## Neden Asenkron Tercih Edildi?

1. **Ölçeklenebilirlik:**
   - Aynı donanımla daha fazla kullanıcıya hizmet
   - Daha az sunucu maliyeti
   - Daha iyi performans

2. **Kaynak Kullanımı:**
   - Thread'ler verimli kullanılır
   - Bellek tüketimi azalır
   - CPU kullanımı optimize olur

3. **Kullanıcı Deneyimi:**
   - Daha hızlı yanıt süreleri
   - Daha az timeout hatası
   - Daha stabil sistem

## İsteği Takip Etmek

Asenkron kodun takibi zor görünebilir, ama modern araçlarla kolaylaştırılabilir:

1. **Request ID:**
   ```csharp
   [HttpPost("login")]
   public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
   {
       var requestId = HttpContext.TraceIdentifier;
       _logger.LogInformation($"[{requestId}] Login başladı: {request.SiteCode}");
       
       var connectionString = await _tenantService.GetConnectionStringAsync(request.SiteCode);
       _logger.LogInformation($"[{requestId}] Connection string alındı");
       
       // ... devamı ...
   }
   ```

2. **Distributed Tracing:**
   - Azure Application Insights
   - Elasticsearch + Kibana
   - Zipkin
   gibi araçlarla tüm akış izlenebilir

## Özet

Asenkron programlama:
- Modern web uygulamaları için standart
- Daha iyi performans ve ölçeklenebilirlik
- Başta öğrenmesi zor ama değer
- Doğru araçlarla takibi kolay
- Maliyetleri düşürür 

## Task, Await ve Async Kavramları

### Task Nedir?
`Task`, gelecekte tamamlanacak bir işi temsil eder. Örneğin:
```csharp
// Task<string> = Gelecekte bir string değer döndürecek iş
Task<string> connectionStringTask = _tenantService.GetConnectionStringAsync("site1");

// Task = Gelecekte tamamlanacak, değer döndürmeyen iş
Task saveTask = _context.SaveChangesAsync();
```

### Await Ne İşe Yarar?
`await`, bir Task'in tamamlanmasını beklemek için kullanılır:
```csharp
// await olmadan:
Task<string> connectionStringTask = _tenantService.GetConnectionStringAsync("site1");
// Bu noktada connectionStringTask henüz tamamlanmamış olabilir!

// await ile:
string connectionString = await _tenantService.GetConnectionStringAsync("site1");
// Bu noktada connectionString değeri hazır!
```

### Async Keyword'ü Ne Yapar?
`async` keyword'ü, bir metodun içinde `await` kullanılabileceğini belirtir:
```csharp
// YANLIŞ - await kullanmak için async gerekli
public Task<string> GetDataWrong()
{
    var result = await _service.GetAsync(); // HATA!
    return result;
}

// DOĞRU - async ve await birlikte
public async Task<string> GetDataCorrect()
{
    var result = await _service.GetAsync(); // OK
    return result;
}
```

### Pratik Örnekler

1. **Basit Async Metot:**
```csharp
// Senkron versiyon
public string GetUserName(int userId)
{
    var user = _context.Users.FirstOrDefault(u => u.Id == userId);
    return user?.Name ?? "Bulunamadı";
}

// Asenkron versiyon
public async Task<string> GetUserNameAsync(int userId)
{
    var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
    return user?.Name ?? "Bulunamadı";
}
```

2. **Birden Fazla Async İşlem:**
```csharp
public async Task<UserDetailsDto> GetUserDetailsAsync(int userId)
{
    // İki async işlemi paralel başlat
    Task<User> userTask = _context.Users.FindAsync(userId);
    Task<List<Order>> ordersTask = _context.Orders
        .Where(o => o.UserId == userId)
        .ToListAsync();

    // İkisinin de bitmesini bekle
    var user = await userTask;
    var orders = await ordersTask;

    return new UserDetailsDto
    {
        UserName = user.Name,
        OrderCount = orders.Count
    };
}
```

3. **Hata Yönetimi:**
```csharp
public async Task<ActionResult<string>> GetSafeDataAsync()
{
    try 
    {
        var data = await _service.GetDataAsync();
        return Ok(data);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Veri alınamadı");
        return StatusCode(500, "Bir hata oluştu");
    }
}
```

### Önemli Noktalar

1. **Task vs Task<T>:**
   - `Task`: Değer döndürmeyen asenkron işlem
   - `Task<T>`: T tipinde değer döndüren asenkron işlem

2. **async void Kullanımı:**
   ```csharp
   // KÖTÜ - hata yönetimi zor
   public async void BadMethod() 
   {
       await Task.Delay(1000);
   }

   // İYİ - Task döndür
   public async Task GoodMethod() 
   {
       await Task.Delay(1000);
   }
   ```

3. **ConfigureAwait:**
   ```csharp
   // Web API'de gerekli değil
   await _service.GetDataAsync();

   // Library geliştirirken önemli
   await _service.GetDataAsync().ConfigureAwait(false);
   ``` 

## Senkron vs Asenkron: Detaylı Çalışma Mantığı

### Thread (İş Parçacığı) Nedir?
Thread, programın çalıştırdığı bir iş parçacığıdır. Her thread:
- Belirli miktarda bellek kullanır (yaklaşık 1MB)
- İşlemci zamanı tüketir
- Sistemde sınırlı sayıda olabilir (örn. IIS'de varsayılan 1024 thread)

### Senkron Çalışma Mantığı
```csharp
public string GetUserData(int userId)
{
    // 1. Thread burada bekler (blocking)
    var user = _context.Users.FirstOrDefault(u => u.Id == userId); // ~100ms
    
    // 2. Thread hala bekliyor
    var orders = _context.Orders.Where(o => o.UserId == userId).ToList(); // ~200ms
    
    // 3. Thread toplam 300ms boyunca bloklanmış oldu
    return $"Kullanıcı: {user.Name}, Sipariş Sayısı: {orders.Count}";
}
```

**Ne Oluyor?**
1. Thread veritabanından yanıt gelene kadar BLOKLANIR
2. Bu sürede başka hiçbir iş yapamaz
3. 100 kullanıcı aynı anda istekte bulunursa 100 thread bloklanır
4. Thread havuzu tükenebilir (thread pool starvation)

### Asenkron Çalışma Mantığı
```csharp
public async Task<string> GetUserDataAsync(int userId)
{
    // 1. Thread DB'ye istek yapar ve SERBEST KALIR
    var userTask = _context.Users.FirstOrDefaultAsync(u => u.Id == userId); // Thread serbest!
    
    // 2. Aynı thread başka isteklere bakabilir
    var ordersTask = _context.Orders.Where(o => o.UserId == userId).ToListAsync(); // Thread yine serbest!
    
    // 3. Sonuçları beklerken thread başka işler yapabilir
    var user = await userTask; // Hazır olunca devam et
    var orders = await ordersTask; // Hazır olunca devam et
    
    return $"Kullanıcı: {user.Name}, Sipariş Sayısı: {orders.Count}";
}
```

**Ne Oluyor?**
1. Thread DB'ye isteği yapar ve HEMEN serbest kalır
2. DB işi yaparken thread başka isteklere bakabilir
3. 100 kullanıcı aynı anda istekte bulunsa bile çok daha az thread yeterli olur
4. Thread havuzu verimli kullanılır

### Performans Karşılaştırması

**Senaryo 1: 100 Eşzamanlı İstek**
- **Senkron:**
  - 100 thread bloklanır
  - Her thread 300ms bekler
  - Toplam bellek: ~100MB (100 thread × 1MB)
  - Maksimum throughput: ~333 istek/saniye

- **Asenkron:**
  - 10-20 thread yeterli
  - Thread'ler bloklanmaz
  - Toplam bellek: ~20MB (20 thread × 1MB)
  - Maksimum throughput: ~1000+ istek/saniye

**Senaryo 2: Yoğun I/O İşlemleri**
```csharp
// Senkron - KÖTÜ
public List<string> GetMultipleData()
{
    var result1 = _service1.GetData(); // 500ms
    var result2 = _service2.GetData(); // 500ms
    var result3 = _service3.GetData(); // 500ms
    // Toplam: 1500ms ve 1 thread bloklandı
    return new List<string> { result1, result2, result3 };
}

// Asenkron - İYİ
public async Task<List<string>> GetMultipleDataAsync()
{
    var task1 = _service1.GetDataAsync(); // Hemen başla
    var task2 = _service2.GetDataAsync(); // Hemen başla
    var task3 = _service3.GetDataAsync(); // Hemen başla
    
    // Hepsi paralel çalışır - Toplam ~500ms
    var results = await Task.WhenAll(task1, task2, task3);
    return results.ToList();
}
```

### Gerçek Dünya Performans Etkileri

1. **Sunucu Maliyetleri:**
   - Senkron: Daha fazla sunucu gerekir
   - Asenkron: Aynı donanımla 5-10 kat daha fazla istek

2. **Kullanıcı Deneyimi:**
   - Senkron: Yoğun zamanlarda timeout
   - Asenkron: Daha tutarlı yanıt süreleri

3. **Ölçeklenebilirlik:**
   - Senkron: Dikey ölçekleme gerekir (daha güçlü sunucu)
   - Asenkron: Yatay ölçekleme yeterli (daha fazla küçük sunucu)

### Ne Zaman Asenkron Kullanmalı?

**Asenkron Kullanın:**
- I/O işlemlerinde (DB, dosya, network)
- Uzun süren işlemlerde
- Çok sayıda paralel istek varsa
- Mikroservis mimarisinde

**Senkron Kullanın:**
- CPU-yoğun işlemlerde
- Çok kısa süren işlemlerde
- Başka thread'e geçiş maliyeti işlem süresinden uzunsa 