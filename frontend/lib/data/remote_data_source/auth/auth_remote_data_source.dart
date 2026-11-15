import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/device_zone.dart';
import 'dto/account_dto.dart';
import 'dto/auth_response_dto.dart';

/// Endpoints de autenticación y cuenta (`/api/v1/auth`, `/api/v1/me`).
class AuthRemoteDataSource {
  AuthRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<AuthResponseDto> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponseDto.fromJson(response.data!);
  }

  Future<AuthResponseDto> register(
    String email,
    String password,
    String fullName, {
    String? acceptedLegalVersion,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/register',
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'acceptedLegalVersion': ?acceptedLegalVersion,
      },
    );
    return AuthResponseDto.fromJson(response.data!);
  }

  Future<AuthResponseDto> loginWithGoogle(String idToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/google',
      data: {'idToken': idToken},
    );
    return AuthResponseDto.fromJson(response.data!);
  }

  Future<void> logout(String refreshToken) => _dio.post<void>(
    '/api/v1/auth/logout',
    data: {'refreshToken': refreshToken},
  );

  // La zona del móvil hace que la edad cambie el mismo día que la tarjeta de
  // cumpleaños de Inicio (ADR 0036).
  Future<AccountDto> me() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/me',
      queryParameters: {'zone': deviceZoneOffset()},
    );
    return AccountDto.fromJson(response.data!);
  }

  Future<AccountDto> updateMe(Map<String, dynamic> changes) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/me',
      queryParameters: {'zone': deviceZoneOffset()},
      data: changes,
    );
    return AccountDto.fromJson(response.data!);
  }

  /// Foto de perfil (campo `file`); el servidor la prepara y devuelve la
  /// cuenta con su dirección nueva (ADR 0052).
  Future<AccountDto> uploadAvatar(
    List<int> bytes,
    String fileName,
    String mimeType,
  ) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/me/avatar',
      queryParameters: {'zone': deviceZoneOffset()},
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return AccountDto.fromJson(response.data!);
  }

  Future<AccountDto> removeAvatar() async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/v1/me/avatar',
      queryParameters: {'zone': deviceZoneOffset()},
    );
    return AccountDto.fromJson(response.data!);
  }

  Future<void> requestPasswordReset(String email) =>
      _dio.post<void>('/api/v1/auth/password-reset', data: {'email': email});

  Future<void> resetPassword(String token, String newPassword) =>
      _dio.post<void>(
        '/api/v1/auth/password-reset/confirm',
        data: {'token': token, 'newPassword': newPassword},
      );

  Future<void> changePassword(String? currentPassword, String newPassword) =>
      _dio.put<void>(
        '/api/v1/me/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
}
