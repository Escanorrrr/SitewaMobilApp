import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'failures.dart';

class ErrorHandler {
  static String handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is Failure) {
      return error.message;
    } else {
      return 'Beklenmeyen bir hata oluştu';
    }
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Bağlantı zaman aşımına uğradı';
      case DioExceptionType.sendTimeout:
        return 'İstek zaman aşımına uğradı';
      case DioExceptionType.receiveTimeout:
        return 'Yanıt zaman aşımına uğradı';
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'İstek iptal edildi';
      case DioExceptionType.connectionError:
        return 'İnternet bağlantınızı kontrol edin';
      default:
        return 'Bir hata oluştu';
    }
  }

  static String _handleBadResponse(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Geçersiz istek';
      case 401:
        return 'Oturum süresi doldu';
      case 403:
        return 'Yetkisiz erişim';
      case 404:
        return 'İstek bulunamadı';
      case 500:
        return 'Sunucu hatası';
      default:
        return 'Bir hata oluştu';
    }
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
} 