# Navigation Property'ler Detaylı Açıklama

## Navigation Property Nedir?

Navigation property'ler, Entity Framework'te entity'ler arasındaki ilişkileri temsil eden özelliklerdir. Bu özellikler, veritabanındaki foreign key ilişkilerini kod tarafında nesne referansları olarak kullanmamızı sağlar.

## Navigation Property Olmadan Nasıl Olur?

### 1. Navigation Property Olmadan
```csharp
// Entity tanımı
public class User
{
    public int Id { get; set; }
    public int RoleId { get; set; }  // Sadece foreign key
}

// Kullanım örneği
var user = await dbContext.Users.FirstAsync(u => u.Id == 1);
var role = await dbContext.Roles.FirstAsync(r => r.Id == user.RoleId);
```

### 2. Navigation Property İle
```csharp
// Entity tanımı
public class User
{
    public int Id { get; set; }
    public int RoleId { get; set; }      // Foreign key
    public Role Role { get; set; }       // Navigation property
}

// Kullanım örneği
var user = await dbContext.Users
    .Include(u => u.Role)
    .FirstAsync(u => u.Id == 1);
var roleName = user.Role.Name;  // Direkt erişim
```

## Navigation Property'lerin Avantajları

1. **Kolay Erişim**
   - İlişkili entity'lere direkt erişim sağlar
   - Kod okunabilirliğini artırır
   - Nesne yönelimli programlamaya daha uygundur

2. **Lazy/Eager Loading Kontrolü**
   ```csharp
   // Lazy loading
   public class User
   {
       public virtual Role Role { get; set; }  // virtual keyword'ü ile lazy loading
   }

   // Eager loading
   var user = await dbContext.Users
       .Include(u => u.Role)          // Role bilgisi de yüklenir
       .Include(u => u.Permissions)   // Permissions de yüklenir
       .FirstAsync(u => u.Id == 1);
   ```

3. **LINQ Sorgularında Kolaylık**
   ```csharp
   // Navigation property olmadan
   var users = await dbContext.Users
       .Join(dbContext.Roles,
           u => u.RoleId,
           r => r.Id,
           (u, r) => new { User = u, RoleName = r.Name })
       .ToListAsync();

   // Navigation property ile
   var users = await dbContext.Users
       .Include(u => u.Role)
       .Select(u => new { User = u, RoleName = u.Role.Name })
       .ToListAsync();
   ```

## Navigation Property Türleri

1. **Reference Navigation Property**
   ```csharp
   public class User
   {
       public Role Role { get; set; }  // Tekil ilişki (One)
   }
   ```

2. **Collection Navigation Property**
   ```csharp
   public class Role
   {
       public ICollection<User> Users { get; set; }  // Çoğul ilişki (Many)
   }
   ```

## Navigation Property'siz Çalışmak Mümkün mü?

Evet, mümkün ancak:

1. **Dezavantajları**
   - Daha fazla kod yazmanız gerekir
   - Join işlemleri manuel yapılmalıdır
   - İlişkili veriye erişim zorlaşır
   - Kod okunabilirliği azalır

2. **Ne Zaman Navigation Property Kullanılmaz?**
   - Çok basit, tek tablolu uygulamalarda
   - Sadece ID bazlı işlemler yapılacaksa
   - Memory kullanımının çok kritik olduğu durumlarda
   - İlişkili veriye hiç ihtiyaç duyulmayacaksa

## Best Practices

1. **Initialization**
   ```csharp
   public class Role
   {
       // Collection navigation property'leri initialize et
       public ICollection<User> Users { get; set; } = new List<User>();
   }
   ```

2. **Nullable Kullanımı**
   ```csharp
   public class User
   {
       public int? ManagerId { get; set; }               // Nullable foreign key
       public User? Manager { get; set; }                // Nullable navigation property
       public ICollection<User> Reports { get; set; }    // Collection property'ler nullable olmaz
   }
   ```

3. **Circular Reference Önleme**
   ```csharp
   // DTO'larda
   public class UserDto
   {
       public int Id { get; set; }
       public string Name { get; set; }
       public RoleDto Role { get; set; }  // Sadece gerekli property'leri içeren DTO
   }
   ```

## Performance İpuçları

1. **Explicit Loading**
   ```csharp
   var user = await dbContext.Users.FindAsync(1);
   // Role sadece gerektiğinde yüklenir
   await dbContext.Entry(user).Reference(u => u.Role).LoadAsync();
   ```

2. **Filtered Include**
   ```csharp
   var users = await dbContext.Users
       .Include(u => u.Role.Permissions.Where(p => p.IsActive))
       .ToListAsync();
   ```

3. **Select ile Optimizasyon**
   ```csharp
   var userNames = await dbContext.Users
       .Select(u => new { u.Id, u.Username, RoleName = u.Role.Name })
       .ToListAsync();
   ``` 