import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lesson_group.dart';
import 'auth_service.dart';

class LessonGroupService {
  static const String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _authService = AuthService();

  Future<List<LessonGroup>> getLessonGroups({
    int page = 1,
    int limit = 50,
    String? search,
    String? teacherId,
    String? studentId,
    String? courseId,
    String? roomId,
    String? days,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (teacherId != null) queryParams['teacherId'] = teacherId;
      if (studentId != null) queryParams['studentId'] = studentId;
      if (courseId != null) queryParams['courseId'] = courseId;
      if (roomId != null) queryParams['roomId'] = roomId;
      if (days != null) queryParams['days'] = days;

      final uri = Uri.parse('$baseUrl/lesson-groups').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as dynamic;
        if (data is Map) {
          final groupsData = data['lessonGroups'] ?? data['data'] ?? [];
          if (groupsData is List) {
            return groupsData.map((json) => LessonGroup.fromJson(json as Map<String, dynamic>)).toList();
          }
        } else if (data is List) {
          return data.map((json) => LessonGroup.fromJson(json as Map<String, dynamic>)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load lesson groups: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching lesson groups: $e');
    }
  }

  Future<LessonGroup?> getLessonGroupById(String groupId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/lesson-groups/$groupId'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LessonGroup.fromJson(data);
      } else {
        throw Exception('Failed to load lesson group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching lesson group: $e');
    }
  }

  Future<bool> createLessonGroup(Map<String, dynamic> groupData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/lesson-groups'),
        headers: headers,
        body: jsonEncode(groupData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to create lesson group: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating lesson group: $e');
    }
  }

  Future<bool> updateLessonGroup(String id, Map<String, dynamic> groupData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/lesson-groups/$id'),
        headers: headers,
        body: jsonEncode(groupData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update lesson group: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating lesson group: $e');
    }
  }

  Future<bool> deleteLessonGroup(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/lesson-groups/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Failed to delete lesson group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting lesson group: $e');
    }
  }
}
