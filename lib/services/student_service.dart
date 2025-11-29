import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lesson_group.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import 'auth_service.dart';

class StudentService {
  final String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _auth = AuthService();

  Future<List<LessonGroup>> getLessonGroups({int page = 1, int limit = 50}) async {
    final headers = await _auth.getAuthHeaders();
    final url = Uri.parse('$baseUrl/lessonGroups?page=$page&limit=$limit');
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List<dynamic> groups = body['lessonGroups'] ?? body['data'] ?? [];
      return groups.map((e) => LessonGroup.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load lesson groups: ${res.statusCode}');
    }
  }

  /// Returns flattened attendance records for a student: one entry per student-record
  Future<List<Map<String, dynamic>>> getAttendanceForStudent(String studentId, {int page = 1, int limit = 50}) async {
    final headers = await _auth.getAuthHeaders();
    final url = Uri.parse('$baseUrl/attendanceRecords?page=$page&limit=$limit&studentId=$studentId');
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List<dynamic> attendanceObjects = body['attendanceRecords'] ?? body['data'] ?? [];
      final List<Map<String, dynamic>> flattened = [];
      for (final att in attendanceObjects) {
        final lessonGroup = att['lessonGroupId'];
        final lgName = lessonGroup is Map ? (lessonGroup['name'] ?? '') : '';
        final records = att['records'] as List<dynamic>? ?? [];
        for (final r in records) {
          final studentObj = r['studentId'];
          flattened.add({
            'attendanceId': att['_id'] ?? '',
            'date': att['date'] ?? '',
            'lessonGroupName': lgName,
            'studentId': studentObj is Map ? (studentObj['_id'] ?? '') : '',
            'studentName': studentObj is Map ? (studentObj['name'] ?? studentObj['phoneNumber'] ?? '') : '',
            'status': r['status'] ?? '',
            'comment': r['comment'] ?? '',
          });
        }
      }
      return flattened;
    } else {
      throw Exception('Failed to load attendance: ${res.statusCode}');
    }
  }

  Future<List<Student>> getStudents({int page = 1, int limit = 50}) async {
    final headers = await _auth.getAuthHeaders();
    final url = Uri.parse('$baseUrl/users?role=STUDENT&page=$page&limit=$limit');
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List<dynamic> students = body['users'] ?? body['data'] ?? [];
      return students.map((e) => Student.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load students: ${res.statusCode}');
    }
  }

  Future<bool> deleteStudent(String studentId) async {
    final headers = await _auth.getAuthHeaders();
    final url = Uri.parse('$baseUrl/users/$studentId');
    final res = await http.delete(url, headers: headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return true;
    } else {
      throw Exception('Failed to delete student: ${res.statusCode}');
    }
  }
}
