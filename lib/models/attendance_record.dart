class AttendanceStudent {
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String status; // present, absent, late
  final String comment;

  AttendanceStudent({
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.status,
    this.comment = '',
  });

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) {
    final student = json['studentId'];
    String studentIdValue = '';
    String studentNameValue = '';
    String studentPhoneValue = '';

    if (student is Map<String, dynamic>) {
      studentIdValue = (student['_id'] ?? student['id'] ?? '').toString();
      studentNameValue = (student['name'] ?? '').toString();
      studentPhoneValue = (student['phoneNumber'] ?? '').toString();
    } else if (student is String) {
      studentIdValue = student;
    }

    return AttendanceStudent(
      studentId: studentIdValue,
      studentName: studentNameValue,
      studentPhone: studentPhoneValue,
      status: json['status'] as String? ?? 'absent',
      comment: json['comment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'status': status,
      if (comment.isNotEmpty) 'comment': comment,
    };
  }

  AttendanceStudent copyWith({String? status, String? comment}) {
    return AttendanceStudent(
      studentId: studentId,
      studentName: studentName,
      studentPhone: studentPhone,
      status: status ?? this.status,
      comment: comment ?? this.comment,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String lessonGroupId;
  final String lessonGroupName;
  final DateTime date;
  final String teacherId;
  final String teacherName;
  final String teacherPhone;
  final String organizationId;
  final String organizationName;
  final List<AttendanceStudent> records;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecord({
    required this.id,
    required this.lessonGroupId,
    required this.lessonGroupName,
    required this.date,
    required this.teacherId,
    required this.teacherName,
    required this.teacherPhone,
    required this.organizationId,
    required this.organizationName,
    required this.records,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    // Parse lesson group
    final lessonGroup = json['lessonGroupId'];
    String lessonGroupIdValue = '';
    String lessonGroupNameValue = '';
    if (lessonGroup is Map<String, dynamic>) {
      lessonGroupIdValue = (lessonGroup['_id'] ?? lessonGroup['id'] ?? '').toString();
      lessonGroupNameValue = (lessonGroup['name'] ?? '').toString();
    } else if (lessonGroup is String) {
      lessonGroupIdValue = lessonGroup;
    }

    // Parse teacher
    final teacher = json['teacherId'];
    String teacherIdValue = '';
    String teacherNameValue = '';
    String teacherPhoneValue = '';
    if (teacher is Map<String, dynamic>) {
      teacherIdValue = (teacher['_id'] ?? teacher['id'] ?? '').toString();
      teacherNameValue = (teacher['name'] ?? '').toString();
      teacherPhoneValue = (teacher['phoneNumber'] ?? '').toString();
    } else if (teacher is String) {
      teacherIdValue = teacher;
    }

    // Parse organization
    final organization = json['organizationId'];
    String organizationIdValue = '';
    String organizationNameValue = '';
    if (organization is Map<String, dynamic>) {
      organizationIdValue = (organization['_id'] ?? organization['id'] ?? '').toString();
      organizationNameValue = (organization['name'] ?? '').toString();
    } else if (organization is String) {
      organizationIdValue = organization;
    }

    // Parse records
    final recordsList = (json['records'] as List<dynamic>?)
            ?.map((r) => AttendanceStudent.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return AttendanceRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      lessonGroupId: lessonGroupIdValue,
      lessonGroupName: lessonGroupNameValue,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      teacherId: teacherIdValue,
      teacherName: teacherNameValue,
      teacherPhone: teacherPhoneValue,
      organizationId: organizationIdValue,
      organizationName: organizationNameValue,
      records: recordsList,
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
      'lessonGroupId': lessonGroupId,
      'date': date.toIso8601String(),
      'teacherId': teacherId,
      'organizationId': organizationId,
      'records': records.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  int get presentCount => records.where((r) => r.status == 'present').length;
  int get absentCount => records.where((r) => r.status == 'absent').length;
  int get lateCount => records.where((r) => r.status == 'late').length;
  int get totalStudents => records.length;
}
