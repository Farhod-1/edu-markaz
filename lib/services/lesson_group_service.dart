import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lesson_group.dart';
import 'auth_service.dart';

/// Service for managing lesson groups via the API
///
/// API Endpoints:
/// - GET    /lesson-groups              - Get all lesson groups with filters
/// - POST   /lesson-groups              - Create a new lesson group
/// - GET    /lesson-groups/{id}         - Get specific lesson group
/// - PATCH  /lesson-groups/{id}         - Update a lesson group
/// - DELETE /lesson-groups/{id}         - Delete a lesson group
/// - GET    /lesson-groups/{id}/relationships - Get detailed relationships
/// - POST   /lesson-groups/{id}/students/{studentId} - Add student
/// - DELETE /lesson-groups/{id}/students/{studentId} - Remove student
/// - POST   /lesson-groups/{id}/teachers/{teacherId} - Assign teacher
/// - DELETE /lesson-groups/{id}/teachers - Remove teacher
class LessonGroupService {
  static const String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _authService = AuthService();

  /// GET /lesson-groups
  /// Get all lesson groups with optional filters and pagination
  ///
  /// Parameters:
  /// - [page]: Page number (starts from 1), default: 1
  /// - [limit]: Number of items per page, default: 10
  /// - [search]: Search term for name (e.g., "mathematics")
  /// - [teacherId]: Filter by teacher ID
  /// - [studentId]: Filter by student ID
  /// - [courseId]: Filter by course ID
  /// - [roomId]: Filter by room ID
  /// - [days]: Filter by specific days (monday, tuesday, wednesday, thursday, friday, saturday, sunday)
  Future<List<LessonGroup>> getLessonGroups({
    int page = 1,
    int limit = 10,
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
      if (teacherId != null && teacherId.isNotEmpty)
        queryParams['teacherId'] = teacherId;
      if (studentId != null && studentId.isNotEmpty)
        queryParams['studentId'] = studentId;
      if (courseId != null && courseId.isNotEmpty)
        queryParams['courseId'] = courseId;
      if (roomId != null && roomId.isNotEmpty) queryParams['roomId'] = roomId;
      if (days != null && days.isNotEmpty) queryParams['days'] = days;

      final uri = Uri.parse('$baseUrl/lesson-groups')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as dynamic;

        // Handle different response formats
        if (data is Map<String, dynamic>) {
          final groupsData =
              data['lessonGroups'] ?? data['data'] ?? data['groups'] ?? [];
          if (groupsData is List) {
            return groupsData
                .map((json) =>
                    LessonGroup.fromJson(json as Map<String, dynamic>))
                .toList();
          }
        } else if (data is List) {
          return data
              .map((json) => LessonGroup.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        return [];
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] ?? 'Failed to load lesson groups';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching lesson groups: $e');
    }
  }

  /// GET /lesson-groups/{id}
  /// Get a specific lesson group by ID
  Future<LessonGroup?> getLessonGroupById(String groupId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/lesson-groups/$groupId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LessonGroup.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] ?? 'Failed to load lesson group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching lesson group: $e');
    }
  }

  /// POST /lesson-groups
  /// Create a new lesson group
  ///
  /// Required fields in [groupData]:
  /// - name: String
  ///
  /// Optional fields:
  /// - teacherId: String (MongoDB ObjectId)
  /// - studentIds: List<String> (array of MongoDB ObjectIds)
  /// - organizationId: String (MongoDB ObjectId)
  /// - days: List<String> (e.g., ["monday", "wednesday", "friday"])
  /// - courseId: String (MongoDB ObjectId)
  /// - roomId: String (MongoDB ObjectId)
  ///
  /// Returns: The created lesson group
  /// Throws: Exception on error (403 if unauthorized)
  Future<LessonGroup> createLessonGroup(Map<String, dynamic> groupData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/lesson-groups'),
        headers: headers,
        body: jsonEncode(groupData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LessonGroup.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception(
            'Forbidden: Only OWNER, ADMIN, and TEACHER can create lesson groups');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] ?? 'Failed to create lesson group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error creating lesson group: $e');
    }
  }

  /// PATCH /lesson-groups/{id}
  /// Update a lesson group
  ///
  /// Parameters:
  /// - [id]: Lesson group ID
  /// - [groupData]: Map containing fields to update (same as create)
  ///
  /// Returns: The updated lesson group
  /// Throws: Exception on error (403 if unauthorized, 404 if not found)
  Future<LessonGroup> updateLessonGroup(
      String id, Map<String, dynamic> groupData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/lesson-groups/$id'),
        headers: headers,
        body: jsonEncode(groupData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LessonGroup.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception(
            'Forbidden: Only OWNER, ADMIN, and TEACHER can update lesson groups');
      } else if (response.statusCode == 404) {
        throw Exception('Lesson group not found');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] ?? 'Failed to update lesson group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error updating lesson group: $e');
    }
  }

  /// DELETE /lesson-groups/{id}
  /// Delete a lesson group
  Future<bool> deleteLessonGroup(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/lesson-groups/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Lesson group not found');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] ?? 'Failed to delete lesson group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error deleting lesson group: $e');
    }
  }

  /// GET /lesson-groups/{id}/relationships
  /// Get detailed relationships for a lesson group
  /// Returns full details of related students, teachers, course, room, etc.
  Future<Map<String, dynamic>> getLessonGroupRelationships(
      String groupId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/lesson-groups/$groupId/relationships'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('Lesson group not found');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] ?? 'Failed to load relationships';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching lesson group relationships: $e');
    }
  }

  /// POST /lesson-groups/{id}/students/{studentId}
  /// Add a student to a lesson group
  Future<bool> addStudentToGroup(String groupId, String studentId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/lesson-groups/$groupId/students/$studentId'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Lesson group or student not found');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] ?? 'Failed to add student to group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error adding student to group: $e');
    }
  }

  /// DELETE /lesson-groups/{id}/students/{studentId}
  /// Remove a student from a lesson group
  Future<bool> removeStudentFromGroup(String groupId, String studentId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/lesson-groups/$groupId/students/$studentId'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Lesson group or student not found');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] ?? 'Failed to remove student from group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error removing student from group: $e');
    }
  }

  /// POST /lesson-groups/{id}/teachers/{teacherId}
  /// Assign a teacher to a lesson group
  Future<bool> assignTeacherToGroup(String groupId, String teacherId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/lesson-groups/$groupId/teachers/$teacherId'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Lesson group or teacher not found');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] ?? 'Failed to assign teacher to group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error assigning teacher to group: $e');
    }
  }

  /// DELETE /lesson-groups/{id}/teachers
  /// Remove teacher from a lesson group
  Future<bool> removeTeacherFromGroup(String groupId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/lesson-groups/$groupId/teachers'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Lesson group not found');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] ?? 'Failed to remove teacher from group';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error removing teacher from group: $e');
    }
  }

  /// Convenience method: Get lesson groups for the current user
  /// Uses the same endpoint as getLessonGroups with default parameters
  Future<List<LessonGroup>> getUserLessonGroups({
    int page = 1,
    int limit = 50,
  }) async {
    return getLessonGroups(page: page, limit: limit);
  }
}
