import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import 'auth_service.dart';

class UserService {
  final String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _auth = AuthService();

  Future<List<Student>> getAllUsers({int page = 1, int limit = 50}) async {
    final headers = await _auth.getAuthHeaders();
    final url = Uri.parse('$baseUrl/users?page=$page&limit=$limit');
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List<dynamic> users = body['users'] ?? body['data'] ?? body;
      return users.map((e) => Student.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load users: ${res.statusCode}');
    }
  }

  Future<List<Student>> getStudents({int page = 1, int limit = 50}) async {
    final headers = await _auth.getAuthHeaders();
    final url = Uri.parse('$baseUrl/users?role=STUDENT&page=$page&limit=$limit');
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List<dynamic> users = body['users'] ?? body['data'] ?? body;
      return users.map((e) => Student.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load students: ${res.statusCode}');
    }
  }

  Future<Student> getUserById(String id) async {
    final headers = await _auth.getAuthHeaders();
    final url = Uri.parse('$baseUrl/users/$id');
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final Map<String, dynamic> data = body['user'] ?? body;
      return Student.fromJson(data);
    } else {
      throw Exception('Failed to load user: ${res.statusCode}');
    }
  }

  // create / update / delete can be added similarly if needed
}
