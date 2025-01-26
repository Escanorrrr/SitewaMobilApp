# Global Exception Handling Yapısı

## Genel Bakış

Global Exception Handling, uygulamada oluşan hataların merkezi bir noktadan yönetilmesini sağlayan bir yapıdır. Bu yapı sayesinde:

1. Kod tekrarını önleriz
2. Tutarlı hata yanıtları üretiriz
3. Hata loglama işlemlerini standartlaştırırız
4. Try-catch bloklarını azaltırız
5. Kod okunabilirliğini artırırız

## Önerilen Yapı

### 1. Exception Tipleri

```csharp
// Base Exception
public class BaseException : Exception
{
    public string ErrorCode { get; }
    public object[] Args { get; }

    public BaseException(string message, string errorCode, params object[] args) 
        : base(message)
    {
        ErrorCode = errorCode;
        Args = args;
    }
}

// Not Found Exception
public class NotFoundException : BaseException
{
    public NotFoundException(string resource, object value) 
        : base($"{resource} not found with value: {value}", "NOT_FOUND", resource, value)
    {
    }
}

// Validation Exception
public class ValidationException : BaseException
{
    public List<ErrorField> ErrorFields { get; }

    public ValidationException(string message, List<ErrorField> errorFields) 
        : base(message, "VALIDATION_ERROR")
    {
        ErrorFields = errorFields;
    }
}

// Business Exception
public class BusinessException : BaseException
{
    public BusinessException(string message, string errorCode, params object[] args) 
        : base(message, errorCode, args)
    {
    }
}
```

### 2. Error Response Model

```csharp
public class ErrorResult
{
    public string Message { get; set; }
    public string ErrorCode { get; set; }
    public List<ErrorField> ErrorFields { get; set; }
    public DateTime Timestamp { get; set; }

    public ErrorResult(string message, string errorCode, List<ErrorField> errorFields = null)
    {
        Message = message;
        ErrorCode = errorCode;
        ErrorFields = errorFields;
        Timestamp = DateTime.UtcNow;
    }
}

public class ErrorField
{
    public string FieldName { get; set; }
    public string Message { get; set; }
}
```

### 3. Global Exception Filter

```csharp
public class GlobalExceptionFilter : IExceptionFilter
{
    private readonly ILogger<GlobalExceptionFilter> _logger;
    private readonly IMessageSource _messageSource;

    public GlobalExceptionFilter(
        ILogger<GlobalExceptionFilter> logger,
        IMessageSource messageSource)
    {
        _logger = logger;
        _messageSource = messageSource;
    }

    public void OnException(ExceptionContext context)
    {
        var errorResult = context.Exception switch
        {
            NotFoundException ex => HandleNotFoundException(ex),
            ValidationException ex => HandleValidationException(ex),
            BusinessException ex => HandleBusinessException(ex),
            _ => HandleUnknownException(context.Exception)
        };

        // Log error
        LogException(context.Exception, errorResult);

        // Set response
        context.Result = new JsonResult(errorResult)
        {
            StatusCode = GetStatusCode(context.Exception)
        };
        
        context.ExceptionHandled = true;
    }

    private ErrorResult HandleNotFoundException(NotFoundException ex)
    {
        return new ErrorResult(
            _messageSource.GetMessage("error.not.found", ex.Args),
            ex.ErrorCode
        );
    }

    private ErrorResult HandleValidationException(ValidationException ex)
    {
        return new ErrorResult(
            ex.Message,
            ex.ErrorCode,
            ex.ErrorFields
        );
    }

    private ErrorResult HandleBusinessException(BusinessException ex)
    {
        return new ErrorResult(
            _messageSource.GetMessage(ex.Message, ex.Args),
            ex.ErrorCode
        );
    }

    private ErrorResult HandleUnknownException(Exception ex)
    {
        return new ErrorResult(
            "Internal Server Error",
            "INTERNAL_SERVER_ERROR"
        );
    }

    private int GetStatusCode(Exception exception) => exception switch
    {
        NotFoundException => StatusCodes.Status404NotFound,
        ValidationException => StatusCodes.Status400BadRequest,
        BusinessException => StatusCodes.Status400BadRequest,
        _ => StatusCodes.Status500InternalServerError
    };

    private void LogException(Exception ex, ErrorResult errorResult)
    {
        var logMessage = $"""
            Exception: {ex.GetType().Name}
            Message: {errorResult.Message}
            ErrorCode: {errorResult.ErrorCode}
            Timestamp: {errorResult.Timestamp}
            StackTrace: {ex.StackTrace}
            """;

        _logger.LogError(ex, logMessage);
    }
}
```

## Geliştirme Adımları

1. **Exception Sınıfları**
   - BaseException oluşturma
   - Özel exception tipleri tanımlama (NotFoundException, ValidationException, vb.)
   - Her exception için gerekli property'leri belirleme

2. **Error Response Model**
   - ErrorResult sınıfı oluşturma
   - ErrorField sınıfı oluşturma
   - Timestamp ve diğer ortak alanları ekleme

3. **Message Source**
   - Hata mesajları için çoklu dil desteği
   - Message template sistemi
   - Resource dosyaları yapılandırması

4. **Global Exception Filter**
   - IExceptionFilter implementasyonu
   - Exception tipine göre handler metotları
   - Loglama mekanizması
   - Status code mapping

5. **Startup Konfigürasyonu**
   - Filter'ı servislere ekleme
   - Loglama konfigürasyonu
   - Message source konfigürasyonu

## Kullanım Örnekleri

### 1. Service Katmanında
```csharp
public class UserService
{
    public async Task<User> GetUser(int id)
    {
        var user = await _userRepository.GetByIdAsync(id);
        if (user == null)
        {
            throw new NotFoundException("User", id);
        }
        return user;
    }

    public async Task CreateUser(CreateUserDto dto)
    {
        var validation = await ValidateUser(dto);
        if (!validation.IsValid)
        {
            throw new ValidationException("Invalid user data", validation.Errors);
        }

        if (await _userRepository.ExistsByUsername(dto.Username))
        {
            throw new BusinessException("error.user.exists", "USER_EXISTS", dto.Username);
        }

        // Create user...
    }
}
```

### 2. Response Örnekleri

```json
// Not Found Error
{
    "message": "User not found with value: 123",
    "errorCode": "NOT_FOUND",
    "errorFields": null,
    "timestamp": "2024-01-28T12:34:56.789Z"
}

// Validation Error
{
    "message": "Invalid user data",
    "errorCode": "VALIDATION_ERROR",
    "errorFields": [
        {
            "fieldName": "username",
            "message": "Username must be at least 3 characters"
        }
    ],
    "timestamp": "2024-01-28T12:34:56.789Z"
}

// Business Error
{
    "message": "User already exists with username: john.doe",
    "errorCode": "USER_EXISTS",
    "errorFields": null,
    "timestamp": "2024-01-28T12:34:56.789Z"
}
```

## Avantajları

1. **Merkezi Hata Yönetimi**
   - Tüm hatalar tek bir noktadan yönetilir
   - Tutarlı hata formatı
   - Kolay bakım ve güncelleme

2. **Temiz Kod**
   - Try-catch blokları azalır
   - Business logic daha temiz olur
   - Hata yönetimi kodu tekrarı önlenir

3. **Gelişmiş Loglama**
   - Standart log formatı
   - Detaylı hata bilgileri
   - Kolay izleme ve debug

4. **Çoklu Dil Desteği**
   - Message source ile mesajlar yönetilir
   - Dinamik mesaj parametreleri
   - Kolay lokalizasyon

5. **Güvenlik**
   - Production'da hassas hata detayları gizlenir
   - Standart hata yanıtları
   - İstemciye uygun bilgi 