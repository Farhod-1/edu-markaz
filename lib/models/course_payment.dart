class CoursePayment {
  final String id;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String lessonGroupId;
  final String lessonGroupName;
  final String? courseId;
  final String? courseName;
  final int amount;
  final String month; // Format: YYYY-MM
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CoursePayment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.lessonGroupId,
    required this.lessonGroupName,
    this.courseId,
    this.courseName,
    required this.amount,
    required this.month,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoursePayment.fromJson(Map<String, dynamic> json) {
    // Parse student
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

    // Parse course
    final course = json['courseId'];
    String? courseIdValue;
    String? courseNameValue;
    if (course is Map<String, dynamic>) {
      courseIdValue = (course['_id'] ?? course['id'] ?? '').toString();
      courseNameValue = (course['name'] ?? '').toString();
    } else if (course is String) {
      courseIdValue = course;
    }

    return CoursePayment(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      studentId: studentIdValue,
      studentName: studentNameValue,
      studentPhone: studentPhoneValue,
      lessonGroupId: lessonGroupIdValue,
      lessonGroupName: lessonGroupNameValue,
      courseId: courseIdValue,
      courseName: courseNameValue,
      amount: json['amount'] as int? ?? 0,
      month: json['month'] as String? ?? '',
      notes: json['notes'] as String?,
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
      'studentId': studentId,
      'lessonGroupId': lessonGroupId,
      if (courseId != null) 'courseId': courseId,
      'amount': amount,
      'month': month,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
