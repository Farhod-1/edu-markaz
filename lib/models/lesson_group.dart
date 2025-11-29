class LessonGroup {
  final String id;
  final String name;
  final String? description;
  final String? courseId;
  final String? courseName;
  final String? teacherId;
  final String? teacherName;
  final String? teacherPhone;
  final List<String> days;
  final String? organizationId;
  final String? organizationName;
  final List<Map<String, dynamic>> studentIds;
  final String? roomId;
  final int? maxStudents;
  final int? currentStudents;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? schedule;
  final DateTime createdAt;
  final DateTime updatedAt;

  LessonGroup({
    required this.id,
    required this.name,
    this.description,
    this.courseId,
    this.courseName,
    this.teacherId,
    this.teacherName,
    this.teacherPhone,
    this.days = const [],
    this.organizationId,
    this.organizationName,
    this.studentIds = const [],
    this.roomId,
    this.maxStudents,
    this.currentStudents,
    required this.status,
    this.startDate,
    this.endDate,
    this.schedule,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LessonGroup.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse dates
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    // Parse teacherId - can be String or populated Object
    String? teacherIdValue;
    String? teacherNameValue;
    String? teacherPhoneValue;
    final teacher = json['teacherId'];
    if (teacher is Map<String, dynamic>) {
      teacherIdValue = (teacher['_id'] ?? teacher['id'] ?? '').toString();
      teacherNameValue = (teacher['name'] ?? '').toString();
      teacherPhoneValue =
          (teacher['phoneNumber'] ?? teacher['phone'] ?? '').toString();
    } else if (teacher is String) {
      teacherIdValue = teacher;
    }

    // Parse courseId - can be String or populated Object
    String? courseIdValue;
    String? courseNameValue;
    final course = json['courseId'];
    if (course is Map<String, dynamic>) {
      courseIdValue = (course['_id'] ?? course['id'] ?? '').toString();
      courseNameValue = (course['name'] ?? '').toString();
    } else if (course is String) {
      courseIdValue = course;
    }

    // Parse organizationId - can be String or populated Object
    String? orgIdValue;
    String? orgNameValue;
    final org = json['organizationId'];
    if (org is Map<String, dynamic>) {
      orgIdValue = (org['_id'] ?? org['id'] ?? '').toString();
      orgNameValue = (org['name'] ?? '').toString();
    } else if (org is String) {
      orgIdValue = org;
    }

    // Parse roomId - can be String or populated Object
    String? roomIdValue;
    final room = json['roomId'];
    if (room is Map<String, dynamic>) {
      roomIdValue = (room['_id'] ?? room['id'] ?? '').toString();
    } else if (room is String) {
      roomIdValue = room;
    }

    // Parse studentIds - can be array of Strings or populated Objects
    final rawStudents = json['studentIds'] as List<dynamic>? ?? [];
    final students = rawStudents.map((student) {
      if (student is Map<String, dynamic>) {
        return Map<String, dynamic>.from(student);
      } else if (student is String) {
        return {'_id': student};
      }
      return <String, dynamic>{};
    }).toList();

    // Parse days
    final daysList =
        (json['days'] as List<dynamic>?)?.map((d) => d.toString()).toList() ??
            [];

    return LessonGroup(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      courseId: courseIdValue,
      courseName: courseNameValue ?? json['courseName'] as String?,
      teacherId: teacherIdValue,
      teacherName: teacherNameValue,
      teacherPhone: teacherPhoneValue,
      days: daysList,
      organizationId: orgIdValue,
      organizationName: orgNameValue ?? json['organizationName'] as String?,
      studentIds: students,
      roomId: roomIdValue,
      maxStudents: json['maxStudents'] as int? ?? json['max_students'] as int?,
      currentStudents: json['currentStudents'] as int? ??
          json['current_students'] as int? ??
          students.length,
      status: json['status'] as String? ?? 'active',
      startDate: parseDate(json['startDate'] ?? json['start_date']),
      endDate: parseDate(json['endDate'] ?? json['end_date']),
      schedule: json['schedule'] as String?,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      if (description != null) 'description': description,
      if (courseId != null) 'courseId': courseId,
      if (courseName != null) 'courseName': courseName,
      if (teacherId != null) 'teacherId': teacherId,
      if (teacherName != null) 'teacherName': teacherName,
      if (teacherPhone != null) 'teacherPhone': teacherPhone,
      'days': days,
      if (organizationId != null) 'organizationId': organizationId,
      if (organizationName != null) 'organizationName': organizationName,
      'studentIds': studentIds,
      if (roomId != null) 'roomId': roomId,
      if (maxStudents != null) 'maxStudents': maxStudents,
      if (currentStudents != null) 'currentStudents': currentStudents,
      'status': status,
      if (startDate != null) 'startDate': startDate?.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
      if (schedule != null) 'schedule': schedule,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters for UI display
  int get studentCount => studentIds.length;

  String get daysDisplay => days.isEmpty ? 'No days set' : days.join(', ');

  bool get hasTeacher => teacherId != null && teacherId!.isNotEmpty;

  bool get isFull {
    if (maxStudents == null || currentStudents == null) return false;
    return currentStudents! >= maxStudents!;
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'full':
        return 'Full';
      default:
        return status;
    }
  }
}
