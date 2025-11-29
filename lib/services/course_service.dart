import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course.dart';
import 'auth_service.dart';

class CourseService {
  static const String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _authService = AuthService();

  Future<List<Course>> getCourses({int page = 1, int limit = 50, String? search}) async {
    try {
      final headers = await _authService.getAuthHeaders();
      String urlStr = '$baseUrl/courses?page=$page&limit=$limit';
      if (search != null && search.isNotEmpty) {
        urlStr += '&search=$search';
      }

      final response = await http.get(
        Uri.parse(urlStr),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as dynamic;
        if (data is Map) {
          final coursesData = data['courses'] ?? data['data'] ?? [];
          if (coursesData is List) {
            return coursesData.map((json) => Course.fromJson(json as Map<String, dynamic>)).toList();
          }
        } else if (data is List) {
          return data.map((json) => Course.fromJson(json as Map<String, dynamic>)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching courses: $e');
    }
  }

  Future<List<Course>> getAllCourses() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/courses/all'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as dynamic;
        if (data is Map) {
          final coursesData = data['courses'] ?? data['data'] ?? [];
          if (coursesData is List) {
            return coursesData.map((json) => Course.fromJson(json as Map<String, dynamic>)).toList();
          }
        } else if (data is List) {
          return data.map((json) => Course.fromJson(json as Map<String, dynamic>)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load all courses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching all courses: $e');
    }
  }

  Future<Course?> getCourseById(String courseId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/courses/$courseId'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Course.fromJson(data);
      } else {
        throw Exception('Failed to load course: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching course: $e');
    }
  }

  Future<bool> createCourse(Map<String, dynamic> courseData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/courses'),
        headers: headers,
        body: jsonEncode(courseData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to create course: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating course: $e');
    }
  }

  Future<bool> updateCourse(String id, Map<String, dynamic> courseData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/courses/$id'),
        headers: headers,
        body: jsonEncode(courseData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update course: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating course: $e');
    }
  }

  Future<bool> deleteCourse(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/courses/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Failed to delete course: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting course: $e');
    }
  }
}
