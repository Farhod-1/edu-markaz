import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_record.dart';
import 'auth_service.dart';

class AttendanceService {
  static const String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getAttendanceRecords({
    String? lessonGroupId,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (lessonGroupId != null && lessonGroupId.isNotEmpty) {
        queryParams['lessonGroupId'] = lessonGroupId;
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['fromDate'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['toDate'] = toDate;
      }

      final uri = Uri.parse('$baseUrl/attendance').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        final attendanceList = (data['attendanceRecords'] as List<dynamic>?)
                ?.map((json) => AttendanceRecord.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];

        return {
          'records': attendanceList,
          'pagination': data['pagination'] ?? {},
        };
      } else {
        throw Exception('Failed to load attendance records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching attendance records: $e');
    }
  }

  Future<AttendanceRecord?> getAttendanceById(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AttendanceRecord.fromJson(data);
      } else {
        throw Exception('Failed to load attendance record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching attendance record: $e');
    }
  }

  Future<bool> createAttendance(Map<String, dynamic> attendanceData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/attendance'),
        headers: headers,
        body: jsonEncode(attendanceData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to create attendance: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating attendance: $e');
    }
  }

  Future<bool> updateAttendance(String id, Map<String, dynamic> attendanceData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/attendance/$id'),
        headers: headers,
        body: jsonEncode(attendanceData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update attendance: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating attendance: $e');
    }
  }

  Future<bool> updateStudentStatus({
    required String attendanceId,
    required String studentId,
    required String status,
    String? comment,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final body = {
        'status': status,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/attendance/$attendanceId/students/$studentId/status'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update student status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating student status: $e');
    }
  }

  Future<bool> deleteAttendance(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/attendance/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Failed to delete attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting attendance: $e');
    }
  }
}
