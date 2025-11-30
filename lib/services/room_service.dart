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

  Future<List<Room>> getAllRooms() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rooms/all'),
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
        throw Exception('Failed to load all rooms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching all rooms: $e');
    }
  }

  Future<Room?> getRoomById(String roomId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rooms/$roomId'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Room.fromJson(data);
      } else {
        throw Exception('Failed to load room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching room: $e');
    }
  }

  Future<bool> createRoom(Map<String, dynamic> roomData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rooms'),
        headers: headers,
        body: jsonEncode(roomData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to create room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating room: $e');
    }
  }

  Future<bool> updateRoom(String id, Map<String, dynamic> roomData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/rooms/$id'),
        headers: headers,
        body: jsonEncode(roomData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating room: $e');
    }
  }

  Future<bool> deleteRoom(String id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/rooms/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Failed to delete room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting room: $e');
    }
  }
}
