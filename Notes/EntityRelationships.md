# Entity İlişkileri ve Veritabanı Yapılandırması

## Entity'ler ve İlişkileri

### 1. User Entity

```csharp
// User entity tanımı
modelBuilder.Entity<User>(entity =>
{
    // Tablo adı
    entity.ToTable("user");

    // Primary Key
    entity.Property(e => e.Id)
        .HasColumnName("Id");

    // Diğer kolonlar
    entity.Property(e => e.Firstname)
        .HasColumnName("Firstname")
        .HasMaxLength(100)
        .IsRequired();

    entity.Property(e => e.Lastname)
        .HasColumnName("Lastname")
        .HasMaxLength(100)
        .IsRequired();

    entity.Property(e => e.Email)
        .HasColumnName("Email")
        .HasMaxLength(100)
        .IsRequired(false);

    entity.Property(e => e.Username)
        .HasColumnName("Username")
        .HasMaxLength(100)
        .IsRequired();

    entity.Property(e => e.Password)
        .HasColumnName("Password")
        .HasMaxLength(255)
        .IsRequired();

    entity.Property(e => e.PhoneNumber)
        .HasColumnName("PhoneNumber")
        .HasMaxLength(20)
        .IsRequired(false);

    entity.Property(e => e.RoleId)
        .HasColumnName("RoleId");

    entity.Property(e => e.IsSuggestionBlocked)
        .HasColumnName("IsSuggestionBlocked")
        .HasDefaultValue(false);

    entity.Property(e => e.ApartmentNumber)
        .HasColumnName("ApartmentNumber")
        .HasMaxLength(50)
        .IsRequired(false);

    entity.Property(e => e.CreatedAt)
        .HasColumnName("CreatedAt");

    // Unique indexler
    entity.HasIndex(e => e.Username).IsUnique();
    entity.HasIndex(e => e.Email).IsUnique();
    entity.HasIndex(e => e.ApartmentNumber).IsUnique();

    // Role ile One-to-Many ilişkisi
    entity.HasOne<Role>()
        .WithMany(r => r.Users)
        .HasForeignKey(u => u.RoleId)
        .OnDelete(DeleteBehavior.Restrict);
});
```

### 2. Role Entity

```csharp
modelBuilder.Entity<Role>(entity =>
{
    // Tablo adı
    entity.ToTable("Role");

    // Primary Key
    entity.Property(e => e.Id)
        .HasColumnName("Id");

    entity.Property(e => e.Name)
        .HasColumnName("Name")
        .HasMaxLength(50)
        .IsRequired();

    // Permission ile Many-to-Many ilişkisi
    entity.HasMany(r => r.Permissions)
        .WithMany(p => p.Roles)
        .UsingEntity<RolePermission>(
            j => j
                .HasOne(rp => rp.Permission)
                .WithMany()
                .HasForeignKey(rp => rp.PermissionId),
            j => j
                .HasOne(rp => rp.Role)
                .WithMany()
                .HasForeignKey(rp => rp.RoleId),
            j =>
            {
                j.ToTable("role_permission");
                j.Property(rp => rp.RoleId).HasColumnName("role_id");
                j.Property(rp => rp.PermissionId).HasColumnName("permission_id");
                j.HasKey(rp => new { rp.RoleId, rp.PermissionId });
            }
        );
});
```

### 3. Permission Entity

```csharp
modelBuilder.Entity<Permission>(entity =>
{
    // Tablo adı
    entity.ToTable("Permission");

    // Primary Key
    entity.Property(e => e.Id)
        .HasColumnName("Id");

    entity.Property(e => e.Name)
        .HasColumnName("Name")
        .HasMaxLength(50)
        .IsRequired();

    entity.Property(e => e.IsPage)
        .HasColumnName("IsPage")
        .HasDefaultValue(false);
});
```

## İlişki Türleri ve Örnekler

### 1. One-to-Many İlişki (User-Role)
- Bir rol birden fazla kullanıcıya sahip olabilir
- Bir kullanıcı sadece bir role sahip olabilir
```csharp
// Role entity'sinde
public ICollection<User> Users { get; set; }

// User entity'sinde
public int RoleId { get; set; }
public Role Role { get; set; }

// İlişki konfigürasyonu
entity.HasOne<Role>()
    .WithMany(r => r.Users)
    .HasForeignKey(u => u.RoleId)
    .OnDelete(DeleteBehavior.Restrict);
```

### 2. Many-to-Many İlişki (Role-Permission)
- Bir rol birden fazla yetkiye sahip olabilir
- Bir yetki birden fazla role sahip olabilir
```csharp
// Role entity'sinde
public ICollection<Permission> Permissions { get; set; }

// Permission entity'sinde
public ICollection<Role> Roles { get; set; }

// Junction (Ara) tablo: RolePermission
public class RolePermission
{
    public int RoleId { get; set; }
    public Role Role { get; set; }
    public int PermissionId { get; set; }
    public Permission Permission { get; set; }
}

// İlişki konfigürasyonu
entity.HasMany(r => r.Permissions)
    .WithMany(p => p.Roles)
    .UsingEntity<RolePermission>(...);
```

## Veritabanı Şeması

```sql
-- User tablosu
CREATE TABLE "user" (
    "Id" SERIAL PRIMARY KEY,
    "Firstname" VARCHAR(100) NOT NULL,
    "Lastname" VARCHAR(100) NOT NULL,
    "Email" VARCHAR(100) UNIQUE,
    "Username" VARCHAR(100) NOT NULL UNIQUE,
    "Password" VARCHAR(255) NOT NULL,
    "PhoneNumber" VARCHAR(20),
    "RoleId" INTEGER NOT NULL,
    "IsSuggestionBlocked" BOOLEAN NOT NULL DEFAULT FALSE,
    "ApartmentNumber" VARCHAR(50) UNIQUE,
    "CreatedAt" TIMESTAMP NOT NULL,
    FOREIGN KEY ("RoleId") REFERENCES "Role"("Id") ON DELETE RESTRICT
);

-- Role tablosu
CREATE TABLE "Role" (
    "Id" SERIAL PRIMARY KEY,
    "Name" VARCHAR(50) NOT NULL
);

-- Permission tablosu
CREATE TABLE "Permission" (
    "Id" SERIAL PRIMARY KEY,
    "Name" VARCHAR(50) NOT NULL,
    "IsPage" BOOLEAN NOT NULL DEFAULT FALSE
);

-- RolePermission (junction) tablosu
CREATE TABLE "role_permission" (
    "role_id" INTEGER NOT NULL,
    "permission_id" INTEGER NOT NULL,
    PRIMARY KEY ("role_id", "permission_id"),
    FOREIGN KEY ("role_id") REFERENCES "Role"("Id"),
    FOREIGN KEY ("permission_id") REFERENCES "Permission"("Id")
);
```

## Önemli Noktalar

1. **Silme Davranışları**
   - User-Role ilişkisinde `Restrict` kullanıldı
   - Yani bir rol silinmeden önce o role ait tüm kullanıcıların silinmesi/taşınması gerekir

2. **Unique Kısıtlamalar**
   - Username
   - Email
   - ApartmentNumber
   için unique index'ler tanımlandı

3. **Nullable Alanlar**
   - Email
   - PhoneNumber
   - ApartmentNumber
   alanları nullable olarak tanımlandı

4. **Varsayılan Değerler**
   - IsSuggestionBlocked: false
   - IsPage: false
   için default değerler tanımlandı

## Navigation Property'ler ve Foreign Key'ler

### Navigation Property Nedir?
Navigation property'ler, entity'ler arasındaki ilişkileri temsil eden özelliklerdir. Örneğin:
```csharp
public class User
{
    // Foreign key property
    public int RoleId { get; set; }
    
    // Navigation property
    public Role Role { get; set }
}
```

### Neden İki Farklı Property Kullanılır?

1. **Foreign Key Property (int RoleId)**
   - Veritabanındaki ilişkiyi temsil eder
   - Performans açısından daha verimlidir
   - Direkt ID üzerinden işlem yapmak için kullanılır
   - Veritabanında fiziksel olarak tutulan değerdir

2. **Navigation Property (Role Role)**
   - Entity'ler arası gezinmeyi sağlar
   - Lazy/Eager loading için kullanılır
   - İlişkili veriye kolay erişim sağlar
   - Veritabanında fiziksel olarak tutulmaz

### RolePermission Sınıfında Neden İkisi de Var?

```csharp
public class RolePermission
{
    // Foreign key properties
    public int RoleId { get; set }
    public int PermissionId { get; set }
    
    // Navigation properties
    public Role Role { get; set }
    public Permission Permission { get; set }
}
```

1. **Foreign Key'ler Neden Var?**
   - Composite primary key oluşturmak için (`RoleId` ve `PermissionId` birlikte)
   - Direkt ID bazlı sorgular için
   - Veritabanı seviyesinde ilişki için
   - Performans optimizasyonu için

2. **Navigation Property'ler Neden Var?**
   - Role ve Permission entity'lerine kolay erişim için
   - Include() ile lazy/eager loading yapabilmek için
   - LINQ sorgularında join işlemlerini kolaylaştırmak için

### Kullanım Örnekleri

1. **Sadece ID Kullanımı**
```csharp
// Performans odaklı
var userId = 1;
var userRole = await dbContext.Users
    .Where(u => u.RoleId == 5)
    .Select(u => u.RoleId)
    .FirstOrDefaultAsync();
```

2. **Navigation Property Kullanımı**
```csharp
// İlişkili veriye erişim
var user = await dbContext.Users
    .Include(u => u.Role)
    .FirstOrDefaultAsync(u => u.Id == 1);

var roleName = user.Role.Name; // Role entity'sine erişim
```

3. **RolePermission Örneği**
```csharp
// ID bazlı sorgu
var rolePerms = await dbContext.RolePermissions
    .Where(rp => rp.RoleId == 5)
    .Select(rp => rp.PermissionId)
    .ToListAsync();

// Navigation property ile sorgu
var rolePerms = await dbContext.RolePermissions
    .Include(rp => rp.Permission)
    .Where(rp => rp.RoleId == 5)
    .Select(rp => rp.Permission.Name)
    .ToListAsync();
```

### Best Practices

1. **Foreign Key Property'ler**
   - Her zaman ilişkiyi temsil eden ID'yi tut
   - Nullable olabilecek ilişkiler için nullable int kullan
   - İsimlendirmede "EntityAdı + Id" formatını kullan

2. **Navigation Property'ler**
   - Lazy loading kullanılacaksa virtual keyword'ü ile işaretle
   - Collection navigation property'leri null olmaması için initialize et
   - Reference navigation property'leri nullable yap

3. **RolePermission gibi Junction Entity'ler**
   - Her iki foreign key'i de required yap
   - Her iki navigation property'yi de ekle
   - Composite key için her iki ID'yi kullan
``` 