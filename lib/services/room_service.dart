import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/room.dart';
import 'auth_service.dart';

class RoomService {
  static const String baseUrl = 'https://edu-markaz.uz/api';
  final AuthService _authService = AuthService();

  Future<List<Room>> getRooms() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rooms'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as dynamic;
        if (data is Map) {
          final roomsData = data['rooms'] ?? data['data'] ?? [];
          if (roomsData is List) {
            return roomsData.map((json) => Room.fromJson(json as Map<String, dynamic>)).toList();
          }
        } else if (data is List) {
          return data.map((json) => Room.fromJson(json as Map<String, dynamic>)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching rooms: $e');
    }
  }
}
