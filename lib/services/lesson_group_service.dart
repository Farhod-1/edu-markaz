import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lesson_group.dart';
import '../utils/id_validator.dart';
import 'auth_service.dart';

class LessonGroupService {
  static const String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _authService = AuthService();

  Future<List<LessonGroup>> getLessonGroups({String? courseId}) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final uri = courseId != null
          ? Uri.parse('$baseUrl/lesson-groups').replace(queryParameters: {'courseId': courseId})
          : Uri.parse('$baseUrl/lesson-groups');
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as dynamic;
        if (data is List) {
          return data.map((json) => LessonGroup.fromJson(json as Map<String, dynamic>)).toList();
        } else if (data is Map && data['data'] != null) {
          final groupsData = data['data'] as List;
          return groupsData.map((json) => LessonGroup.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          return [];
        }
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

  Future<LessonGroup> createLessonGroup({
    required String name,
    required String courseId,
    String? description,
    int? maxStudents,
    DateTime? startDate,
    DateTime? endDate,
    String? schedule,
  }) async {
    try {
      // Validate courseId is a valid MongoDB ObjectId
      final validCourseId = IdValidator.cleanId(courseId);
      if (validCourseId == null) {
        throw Exception('Invalid courseId format. Must be a valid MongoDB ObjectId.');
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/lesson-groups'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'courseId': validCourseId,
          if (description != null && description.isNotEmpty) 'description': description,
          if (maxStudents != null && maxStudents > 0) 'maxStudents': maxStudents,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (schedule != null && schedule.isNotEmpty) 'schedule': schedule,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LessonGroup.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Failed to create lesson group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error creating lesson group: $e');
    }
  }

  Future<LessonGroup> updateLessonGroup({
    required String groupId,
    String? name,
    String? courseId,
    String? description,
    int? maxStudents,
    DateTime? startDate,
    DateTime? endDate,
    String? schedule,
    String? status,
  }) async {
    try {
      // Validate groupId and courseId if provided
      if (!IdValidator.isValidMongoId(groupId)) {
        throw Exception('Invalid groupId format. Must be a valid MongoDB ObjectId.');
      }
      
      final headers = await _authService.getAuthHeaders();
      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (courseId != null) {
        final validCourseId = IdValidator.cleanId(courseId);
        if (validCourseId == null) {
          throw Exception('Invalid courseId format. Must be a valid MongoDB ObjectId.');
        }
        body['courseId'] = validCourseId;
      }
      if (description != null && description.isNotEmpty) body['description'] = description;
      if (maxStudents != null && maxStudents > 0) body['maxStudents'] = maxStudents;
      if (startDate != null) body['startDate'] = startDate.toIso8601String();
      if (endDate != null) body['endDate'] = endDate.toIso8601String();
      if (schedule != null && schedule.isNotEmpty) body['schedule'] = schedule;
      if (status != null && status.isNotEmpty) body['status'] = status;

      final response = await http.patch(
        Uri.parse('$baseUrl/lesson-groups/$groupId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LessonGroup.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Failed to update lesson group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error updating lesson group: $e');
    }
  }

  Future<void> deleteLessonGroup(String groupId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/lesson-groups/$groupId'),
        headers: headers,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Failed to delete lesson group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error deleting lesson group: $e');
    }
  }

  Future<void> addStudentToGroup(String groupId, String studentId) async {
    try {
      // Validate IDs
      if (!IdValidator.isValidMongoId(groupId)) {
        throw Exception('Invalid groupId format. Must be a valid MongoDB ObjectId.');
      }
      final validStudentId = IdValidator.cleanId(studentId);
      if (validStudentId == null) {
        throw Exception('Invalid studentId format. Must be a valid MongoDB ObjectId.');
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/lesson-groups/$groupId/students/$validStudentId'),
        headers: headers,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Failed to add student';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error adding student to group: $e');
    }
  }

  Future<void> removeStudentFromGroup(String groupId, String studentId) async {
    try {
      // Validate IDs
      if (!IdValidator.isValidMongoId(groupId)) {
        throw Exception('Invalid groupId format. Must be a valid MongoDB ObjectId.');
      }
      final validStudentId = IdValidator.cleanId(studentId);
      if (validStudentId == null) {
        throw Exception('Invalid studentId format. Must be a valid MongoDB ObjectId.');
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/lesson-groups/$groupId/students/$validStudentId'),
        headers: headers,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Failed to remove student';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error removing student from group: $e');
    }
  }

  Future<void> assignTeacherToGroup(String groupId, String teacherId) async {
    try {
      // Validate IDs
      if (!IdValidator.isValidMongoId(groupId)) {
        throw Exception('Invalid groupId format. Must be a valid MongoDB ObjectId.');
      }
      final validTeacherId = IdValidator.cleanId(teacherId);
      if (validTeacherId == null) {
        throw Exception('Invalid teacherId format. Must be a valid MongoDB ObjectId.');
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/lesson-groups/$groupId/teachers/$validTeacherId'),
        headers: headers,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Failed to assign teacher';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error assigning teacher to group: $e');
    }
  }

  Future<void> removeTeacherFromGroup(String groupId) async {
    try {
      // Validate groupId
      if (!IdValidator.isValidMongoId(groupId)) {
        throw Exception('Invalid groupId format. Must be a valid MongoDB ObjectId.');
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/lesson-groups/$groupId/teachers'),
        headers: headers,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Failed to remove teacher';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error removing teacher from group: $e');
    }
  }

  Future<List<LessonGroup>> getUserLessonGroups() async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/lesson-groups/my'),
          headers: headers,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body) as dynamic;
          if (data is List) {
            return data.map((json) => LessonGroup.fromJson(json as Map<String, dynamic>)).toList();
          } else if (data is Map && data['data'] != null) {
            final groupsData = data['data'] as List;
            return groupsData.map((json) => LessonGroup.fromJson(json as Map<String, dynamic>)).toList();
          }
        }
      } catch (_) {
        // If /my endpoint fails, fallback to fetching all groups below
      }
      
      return await getLessonGroups();
    } catch (e) {
      throw Exception('Error fetching user lesson groups: $e');
    }
  }
}

