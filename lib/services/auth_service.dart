import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'accessToken';
  static const _userKey = 'user';

  // Save token and user after login
  Future<void> saveAuthData(String token, User user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(
      key: _userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  // Get stored access token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get stored user data
  Future<User?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all auth data (logout)
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  // Get headers with authorization token for API calls
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'accept': '*/*',
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}

