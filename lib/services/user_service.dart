import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/teacher.dart';
import '../models/parent.dart';
import '../models/user.dart';
import 'auth_service.dart';

class UserService {
  final AuthService _authService = AuthService();

  Future<List<Teacher>> getTeachers() async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('${AppConstants.baseUrl}/users?role=teacher');

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('users')) {
          final List<dynamic> usersJson = data['users'];
          return usersJson.map((json) => Teacher.fromJson(json)).toList();
        } else if (data is List) {
          return data.map((json) => Teacher.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      // Handle error or rethrow
      print('Error fetching teachers: $e');
      return [];
    }
  }

  Future<List<Parent>> getParents() async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('${AppConstants.baseUrl}/users?role=parent');

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('users')) {
          final List<dynamic> usersJson = data['users'];
          return usersJson.map((json) => Parent.fromJson(json)).toList();
        } else if (data is List) {
          return data.map((json) => Parent.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching parents: $e');
      return [];
    }
  }

  Future<bool> createTeacher(Map<String, dynamic> teacherData) async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('${AppConstants.baseUrl}/users');

    try {
      teacherData['role'] = 'teacher';

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(teacherData),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error creating teacher: $e');
      return false;
    }
  }

  Future<bool> createParent(Map<String, dynamic> parentData) async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('${AppConstants.baseUrl}/users');

    try {
      parentData['role'] = 'parent';

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(parentData),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error creating parent: $e');
      return false;
    }
  }

  Future<List<User>> getUsers(
      {int page = 1, int limit = 50, String? role}) async {
    final headers = await _authService.getAuthHeaders();
    String url = '${AppConstants.baseUrl}/users?page=$page&limit=$limit';
    if (role != null && role.isNotEmpty) {
      url += '&role=$role';
    }
    final uri = Uri.parse(url);

    try {
      print('Fetching users from: $url');
      final response = await http.get(uri, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('users')) {
          final List<dynamic> usersJson = data['users'];
          print('Found ${usersJson.length} users in response');
          return usersJson.map((json) => User.fromJson(json)).toList();
        } else if (data is List) {
          print('Found ${data.length} users in response (array format)');
          return data.map((json) => User.fromJson(json)).toList();
        }
        print('Response format not recognized');
      }
      return [];
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<List<User>> getStudents({int page = 1, int limit = 50}) async {
    return getUsers(page: page, limit: limit, role: 'student');
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('${AppConstants.baseUrl}/users');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(userData),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> userData) async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('${AppConstants.baseUrl}/users/$userId');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(userData),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('${AppConstants.baseUrl}/users/$userId');

    try {
      final response = await http.delete(uri, headers: headers);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
