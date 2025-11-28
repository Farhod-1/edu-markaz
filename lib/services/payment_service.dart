import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../utils/id_validator.dart';
import 'auth_service.dart';

class PaymentService {
  static const String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _authService = AuthService();

  Future<List<Payment>> getPayments() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/course-payments'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as dynamic;
        if (data is List) {
          return data.map((json) => Payment.fromJson(json as Map<String, dynamic>)).toList();
        } else if (data is Map && data['data'] != null) {
          final paymentsData = data['data'] as List;
          return paymentsData.map((json) => Payment.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load payments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  Future<List<Payment>> getUserPayments({String? studentId}) async {
    if (studentId != null && studentId.isNotEmpty) {
      try {
        return await getPaymentsByStudent(studentId);
      } catch (_) {
        // Fallback to fetching all payments below
      }
    }

    return getPayments();
  }

  Future<Payment> createPayment({
    required String courseId,
    required double amount,
    required String studentId,
    required String month, // Format: "YYYY-MM" as string
    String? lessonGroupId,
    String? paymentMethod,
  }) async {
    try {
      // Validate and clean IDs
      final validCourseId = IdValidator.cleanId(courseId);
      final validStudentId = IdValidator.cleanId(studentId);
      final validLessonGroupId = IdValidator.cleanId(lessonGroupId);

      if (validCourseId == null) {
        throw Exception('Invalid courseId format. Must be a valid MongoDB ObjectId.');
      }
      if (validStudentId == null) {
        throw Exception('Invalid studentId format. Must be a valid MongoDB ObjectId.');
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/course-payments'),
        headers: headers,
        body: jsonEncode({
          'courseId': validCourseId,
          'amount': amount,
          'studentId': validStudentId,
          'month': month, // Must be string in format "YYYY-MM"
          if (validLessonGroupId != null) 'lessonGroupId': validLessonGroupId,
          if (paymentMethod != null && paymentMethod.isNotEmpty) 'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Payment.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Failed to create payment';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  Future<Payment> getPaymentById(String paymentId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/course-payments/$paymentId'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Payment.fromJson(data);
      } else {
        throw Exception('Failed to load payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching payment: $e');
    }
  }

  Future<Payment> updatePayment({
    required String paymentId,
    String? courseId,
    String? studentId,
    String? lessonGroupId,
    double? amount,
    String? status,
    String? paymentMethod,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final body = <String, dynamic>{};
      if (courseId != null) body['courseId'] = courseId;
      if (studentId != null) body['studentId'] = studentId;
      if (lessonGroupId != null) body['lessonGroupId'] = lessonGroupId;
      if (amount != null) body['amount'] = amount;
      if (status != null) body['status'] = status;
      if (paymentMethod != null) body['paymentMethod'] = paymentMethod;

      final response = await http.patch(
        Uri.parse('$baseUrl/course-payments/$paymentId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Payment.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Failed to update payment';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error updating payment: $e');
    }
  }

  Future<void> deletePayment(String paymentId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/course-payments/$paymentId'),
        headers: headers,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['message'] ?? 'Failed to delete payment';
        throw Exception('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error deleting payment: $e');
    }
  }

  Future<List<Payment>> getPaymentsByStudent(String studentId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/course-payments/student/$studentId'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as dynamic;
        if (data is List) {
          return data.map((json) => Payment.fromJson(json as Map<String, dynamic>)).toList();
        } else if (data is Map && data['data'] != null) {
          final paymentsData = data['data'] as List;
          return paymentsData.map((json) => Payment.fromJson(json as Map<String, dynamic>)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load student payments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching student payments: $e');
    }
  }
}

