import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'auth_service.dart';

class UserService {
  final String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _auth = AuthService();

  Future<List<User>> getUsers({int page = 1, int limit = 50, String? role}) async {
    final headers = await _auth.getAuthHeaders();
    var urlString = '$baseUrl/users?page=$page&limit=$limit';
    if (role != null && role.isNotEmpty) {
      urlString += '&role=$role';
    }
    final url = Uri.parse(urlString);
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List<dynamic> users = body['users'] ?? body['data'] ?? [];
      return users.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load users: ${res.statusCode}');
    }
  }

  Future<void> createUser(String phoneNumber, String password, String role, String name) async {
    final headers = await _auth.getAuthHeaders();
    final url = Uri.parse('$baseUrl/users');
    final body = {
      'phoneNumber': phoneNumber,
      'password': password,
      'role': role,
      'name': name,
    };
    
    final res = await http.post(url, headers: headers, body: jsonEncode(body));
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to create user: ${res.body}');
    }
  }

  Future<void> deleteUser(String id) async {
    final headers = await _auth.getAuthHeaders();
    final url = Uri.parse('$baseUrl/users/$id');
    final res = await http.delete(url, headers: headers);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete user: ${res.body}');
    }
  }
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    final headers = await _auth.getAuthHeaders();
    final url = Uri.parse('$baseUrl/users/$id');
    final res = await http.put(url, headers: headers, body: jsonEncode(data));
    if (res.statusCode != 200) {
      throw Exception('Failed to update user: ${res.body}');
    }
  }
}
