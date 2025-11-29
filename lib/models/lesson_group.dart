class LessonGroup {
  final String id;
  final String name;
  final String? description;
  final String? courseId;
  final String? courseName;
  final List<String> days;
  final String? organizationName;
  final List<Map<String, dynamic>> studentIds;
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
    this.days = const [],
    this.organizationName,
    this.studentIds = const [],
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

    // Parse organization name
    final org = json['organizationId'];
    final orgName = org is Map ? (org['name'] ?? '') : (org ?? '');

    // Parse students
    final rawStudents = json['studentIds'] as List<dynamic>? ?? [];
    final students = rawStudents.map((e) => Map<String, dynamic>.from(e)).toList();

    // Parse days
    final daysList = (json['days'] as List<dynamic>?)
            ?.map((d) => d.toString())
            .toList() ??
        [];

    return LessonGroup(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      courseId: json['courseId'] as String? ?? json['course_id'] as String?,
      courseName: json['courseName'] as String?,
      days: daysList,
      organizationName: orgName.toString(),
      studentIds: students,
      maxStudents: json['maxStudents'] as int? ?? json['max_students'] as int?,
      currentStudents: json['currentStudents'] as int? ?? json['current_students'] as int?,
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
      'description': description,
      'courseId': courseId,
      'courseName': courseName,
      'days': days,
      'organizationName': organizationName,
      'studentIds': studentIds,
      'maxStudents': maxStudents,
      'currentStudents': currentStudents,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'schedule': schedule,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

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
