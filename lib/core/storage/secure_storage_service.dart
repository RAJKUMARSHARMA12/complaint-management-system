import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class StorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();

  // Convenience auth storage helpers
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();

  Future<void> saveUserData(Map<String, dynamic> userJson);
  Future<Map<String, dynamic>?> getUserData();
  Future<void> deleteUserData();

  Future<void> clearAuth();
}

abstract class BaseStorageService implements StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  @override
  Future<void> saveToken(String token) => write(_keyToken, token);

  @override
  Future<String?> getToken() => read(_keyToken);

  @override
  Future<void> deleteToken() => delete(_keyToken);

  @override
  Future<void> saveUserData(Map<String, dynamic> userJson) =>
      write(_keyUser, jsonEncode(userJson));

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final raw = await read(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteUserData() => delete(_keyUser);

  @override
  Future<void> clearAuth() async {
    await deleteToken();
    await deleteUserData();
  }
}

class SecureStorageService extends BaseStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

class InMemoryStorageService extends BaseStorageService {
  final Map<String, String> _map = {};

  @override
  Future<void> write(String key, String value) async {
    _map[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _map[key];
  }

  @override
  Future<void> delete(String key) async {
    _map.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _map.clear();
  }
}
