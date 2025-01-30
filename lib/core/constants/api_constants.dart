class ApiConstants {
  static const String baseUrl = 'https://api.example.com';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String userProfile = '/auth/profile';
  
  // Cache Keys
  static const String tokenKey = 'token';
  static const String refreshTokenKey = 'refresh_token';
  static const String siteCodeKey = 'site_code';
  
  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  static const String siteCodeHeader = 'Site-Code';
  
  // Error Messages
  static const String serverError = 'Sunucu hatası';
  static const String unknownError = 'Bilinmeyen bir hata oluştu';
  static const String networkError = 'İnternet bağlantısı hatası';
  static const String timeoutError = 'İstek zaman aşımına uğradı';
} 