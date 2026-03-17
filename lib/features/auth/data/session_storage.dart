import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../exams/domain/models.dart';

class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
  });

  final String accessToken;
  final String refreshToken;
  final UserRole role;
}

class SessionStorage {
  SessionStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _roleKey = 'role';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required UserRole role,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _roleKey, value: jsonEncode(role.name));
  }

  Future<StoredSession?> readSession() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final roleValue = await _storage.read(key: _roleKey);
    if (accessToken == null || refreshToken == null || roleValue == null) {
      return null;
    }

    final role = (jsonDecode(roleValue) as String) == 'examiner' ? UserRole.examiner : UserRole.examinee;
    return StoredSession(accessToken: accessToken, refreshToken: refreshToken, role: role);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _roleKey);
  }
}
