class LessonGroup {
  final String id;
  final String name;
  final List<String> days;
  final String organizationName;
  final List<Map<String, dynamic>> studentIds; // minimal - contains id,name,phoneNumber
  final String? description;
  final String courseId;
  final String? courseName;
  final int? maxStudents;
  final int? currentStudents;
  final String status; // active, inactive, full
  final DateTime? startDate;
  final DateTime? endDate;
  final String? schedule;
  final DateTime createdAt;
  final DateTime updatedAt;

  LessonGroup({
    required this.id,
    required this.name,
    required this.days,
    required this.organizationName,
    required this.studentIds,
  });

  factory LessonGroup.fromJson(Map<String, dynamic> json) {
    final org = json['organizationId'];
    final orgName = org is Map ? (org['name'] ?? '') : (org ?? '');
    final rawStudents = json['studentIds'] as List<dynamic>? ?? [];
    final students = rawStudents.map((e) => Map<String, dynamic>.from(e)).toList();
    return LessonGroup(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      days: (json['days'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          [],
      organizationName: orgName.toString(),
      studentIds: students,
    );
  }
}
    this.description,
    required this.courseId,
    this.courseName,
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
    return LessonGroup(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      courseId: json['courseId'] as String? ?? json['course_id'] as String,
      courseName: json['courseName'] as String?,
      maxStudents: json['maxStudents'] as int? ?? json['max_students'] as int?,
      currentStudents: json['currentStudents'] as int? ?? json['current_students'] as int?,
      status: json['status'] as String? ?? 'active',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : json['start_date'] != null
              ? DateTime.parse(json['start_date'] as String)
              : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : json['end_date'] != null
              ? DateTime.parse(json['end_date'] as String)
              : null,
      schedule: json['schedule'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'courseId': courseId,
      'courseName': courseName,
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

