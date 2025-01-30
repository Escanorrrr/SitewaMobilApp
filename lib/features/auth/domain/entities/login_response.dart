import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_response.freezed.dart';
part 'login_response.g.dart';

@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required String token,
    required String refreshToken,
    required UserInfo user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
class UserInfo with _$UserInfo {
  const factory UserInfo({
    required int id,
    required String firstName,
    required String lastName,
    String? email,
    String? phoneNumber,
    required String username,
    required String role,
    String? apartmentNumber,
  }) = _UserInfo;

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
} 