import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course_payment.dart';
import 'auth_service.dart';

class CoursePaymentService {
  static const String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getCoursePayments({
    String? search,
    String? studentId,
    String? lessonGroupId,
    String? courseId,
    String? month,
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };
      
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (studentId != null && studentId.isNotEmpty) queryParams['studentId'] = studentId;
      if (lessonGroupId != null && lessonGroupId.isNotEmpty) queryParams['lessonGroupId'] = lessonGroupId;
      if (courseId != null && courseId.isNotEmpty) queryParams['courseId'] = courseId;
      if (month != null && month.isNotEmpty) queryParams['month'] = month;

      final uri = Uri.parse('$baseUrl/course-payments').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        final paymentsList = (data['coursePayments'] ?? data['data'] ?? data['payments'] ?? [])
            as List<dynamic>;
        
        final payments = paymentsList
            .map((json) => CoursePayment.fromJson(json as Map<String, dynamic>))
            .toList();

        return {
          'payments': payments,
          'pagination': data['pagination'] ?? {},
        };
      } else {
        throw Exception('Failed to load course payments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching course payments: $e');
    }
  }

  Future<List<CoursePayment>> getStudentPayments(String studentId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/course-payments/student/$studentId'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as dynamic;
        
        List<dynamic> paymentsData;
        if (data is Map) {
          paymentsData = data['coursePayments'] ?? data['data'] ?? data['payments'] ?? [];
        } else if (data is List) {
          paymentsData = data;
        } else {
          return [];
        }

        return paymentsData
            .map((json) => CoursePayment.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load student payments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching student payments: $e');
    }
  }

  Future<CoursePayment?> getPaymentById(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/course-payments/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CoursePayment.fromJson(data);
      } else {
        throw Exception('Failed to load payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching payment: $e');
    }
  }

  Future<bool> createPayment(Map<String, dynamic> paymentData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/course-payments'),
        headers: headers,
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to create payment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  Future<bool> updatePayment(String id, Map<String, dynamic> paymentData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/course-payments/$id'),
        headers: headers,
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update payment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating payment: $e');
    }
  }

  Future<bool> deletePayment(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/course-payments/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Failed to delete payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting payment: $e');
    }
  }
}
