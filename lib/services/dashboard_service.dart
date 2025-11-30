import 'package:edu_markaz/services/course_service.dart';
import 'package:edu_markaz/services/lesson_group_service.dart';
import 'package:edu_markaz/services/room_service.dart';
import 'package:edu_markaz/services/user_service.dart';

class DashboardStats {
  final int studentsCount;
  final int teachersCount;
  final int parentsCount;
  final int lessonGroupsCount;
  final int coursesCount;
  final int roomsCount;

  DashboardStats({
    required this.studentsCount,
    required this.teachersCount,
    required this.parentsCount,
    required this.lessonGroupsCount,
    required this.coursesCount,
    required this.roomsCount,
  });
}

class DashboardService {
  final UserService _userService = UserService();
  final LessonGroupService _lessonGroupService = LessonGroupService();
  final CourseService _courseService = CourseService();
  final RoomService _roomService = RoomService();

  /// Fetch all dashboard statistics
  /// Returns counts for students, teachers, parents, lesson groups, courses, and rooms
  Future<DashboardStats> getStatistics() async {
    try {
      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _fetchStudentsCount(),
        _fetchTeachersCount(),
        _fetchParentsCount(),
        _fetchLessonGroupsCount(),
        _fetchCoursesCount(),
        _fetchRoomsCount(),
      ]);

      return DashboardStats(
        studentsCount: results[0],
        teachersCount: results[1],
        parentsCount: results[2],
        lessonGroupsCount: results[3],
        coursesCount: results[4],
        roomsCount: results[5],
      );
    } catch (e) {
      print('Error fetching dashboard statistics: $e');
      // Return zeros on error
      return DashboardStats(
        studentsCount: 0,
        teachersCount: 0,
        parentsCount: 0,
        lessonGroupsCount: 0,
        coursesCount: 0,
        roomsCount: 0,
      );
    }
  }

  Future<int> _fetchStudentsCount() async {
    try {
      // Use getUsers with uppercase STUDENT role
      final students =
          await _userService.getUsers(limit: 1000, role: 'STUDENT');
      return students.length;
    } catch (e) {
      print('Error fetching students count: $e');
      return 0;
    }
  }

  Future<int> _fetchTeachersCount() async {
    try {
      // Use getUsers with uppercase TEACHER role
      final teachers =
          await _userService.getUsers(limit: 1000, role: 'TEACHER');
      return teachers.length;
    } catch (e) {
      print('Error fetching teachers count: $e');
      return 0;
    }
  }

  Future<int> _fetchParentsCount() async {
    try {
      // Use getUsers with uppercase PARENT role
      final parents = await _userService.getUsers(limit: 1000, role: 'PARENT');
      return parents.length;
    } catch (e) {
      print('Error fetching parents count: $e');
      return 0;
    }
  }

  Future<int> _fetchLessonGroupsCount() async {
    try {
      final lessonGroups =
          await _lessonGroupService.getLessonGroups(limit: 1000);
      return lessonGroups.length;
    } catch (e) {
      print('Error fetching lesson groups count: $e');
      return 0;
    }
  }

  Future<int> _fetchCoursesCount() async {
    try {
      final courses = await _courseService.getCourses(limit: 1000);
      return courses.length;
    } catch (e) {
      print('Error fetching courses count: $e');
      return 0;
    }
  }

  Future<int> _fetchRoomsCount() async {
    try {
      final rooms = await _roomService.getRooms();
      return rooms.length;
    } catch (e) {
      print('Error fetching rooms count: $e');
      return 0;
    }
  }
}
