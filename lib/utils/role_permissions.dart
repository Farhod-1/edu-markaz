class RolePermissions {
  // User roles
  static const String owner = 'OWNER';
  static const String admin = 'ADMIN';
  static const String teacher = 'TEACHER';
  static const String parent = 'PARENT';
  static const String student = 'STUDENT';

  // Check if user can access users management
  static bool canAccessUsers(String role) {
    return role == owner || role == admin;
  }

  // Check if user can access settings
  static bool canAccessSettings(String role) {
    return role == owner || role == admin;
  }

  // Check if user can manage students
  static bool canManageStudents(String role) {
    return role == owner || role == admin;
  }

  // Check if user can manage teachers
  static bool canManageTeachers(String role) {
    return role == owner || role == admin;
  }

  // Check if user can manage parents
  static bool canManageParents(String role) {
    return role == owner || role == admin;
  }

  // Check if user can access payments
  static bool canAccessPayments(String role) {
    return role == owner || role == admin;
  }

  // Check if user can access lesson groups
  static bool canAccessLessonGroups(String role) {
    return role == owner || role == admin || role == teacher;
  }

  // Check if user can manage attendance
  static bool canManageAttendance(String role) {
    return role == owner || role == admin || role == teacher;
  }

  // Check if user can access courses
  static bool canAccessCourses(String role) {
    return role == owner || role == admin;
  }

  // Check if user can access rooms
  static bool canAccessRooms(String role) {
    return role == owner || role == admin;
  }

  // Check if user has access to People tab
  static bool canAccessPeople(String role) {
    return role == owner || role == admin;
  }

  // Check if user has access to Attendance tab
  static bool canAccessAttendance(String role) {
    return role == owner || role == admin || role == teacher;
  }

  // Get role display name
  static String getRoleDisplayName(String role) {
    switch (role) {
      case owner:
        return 'Owner';
      case admin:
        return 'Admin';
      case teacher:
        return 'Teacher';
      case parent:
        return 'Parent';
      case student:
        return 'Student';
      default:
        return role;
    }
  }
}
