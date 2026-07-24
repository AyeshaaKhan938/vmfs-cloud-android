import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? vmfsSecureStorage;

  static const _tokenKey = 'vmfs_auth_token';

  final FlutterSecureStorage _storage;
  String? _memoryToken;

  Future<void> saveToken(String token) async {
    _memoryToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() async {
    if (_memoryToken != null && _memoryToken!.isNotEmpty) {
      return _memoryToken;
    }

    try {
      final token = await _storage
          .read(key: _tokenKey)
          .timeout(const Duration(seconds: 3));
      if (token != null && token.isNotEmpty) {
        _memoryToken = token;
      }
      return token;
    } on TimeoutException {
      return null;
    }
  }

  Future<void> clearToken() async {
    _memoryToken = null;
    await _storage.delete(key: _tokenKey);
  }
}
