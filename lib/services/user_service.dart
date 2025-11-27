import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/teacher.dart';
import '../models/parent.dart';
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
}
