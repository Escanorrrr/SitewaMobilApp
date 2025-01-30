class ApiConstants {
  static const String baseUrl = 'https://api.sitewa.com/v1'; // TODO: API URL'i güncellenecek
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String userProfile = '/user/profile';
  
  // Cache Keys
  static const String tokenKey = 'token';
  static const String refreshTokenKey = 'refresh_token';
  static const String siteCodeKey = 'site_code';
  
  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  static const String siteCodeHeader = 'X-Site-Code';
  
  // Error Messages
  static const String connectionError = 'Bağlantı hatası';
  static const String unauthorizedError = 'Oturum süresi doldu';
  static const String serverError = 'Sunucu hatası';
  static const String unknownError = 'Bilinmeyen bir hata oluştu';
} 