class AttendanceRecord {
  final String id;
  final String date; // keep as string for simple UI
  final String lessonGroupName;
  final String studentId;
  final String studentName;
  final String status;
  final String comment;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.lessonGroupName,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.comment,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final lessonGroup = json['lessonGroupId'];
    final lgName = lessonGroup is Map ? (lessonGroup['name'] ?? '') : '';
    // if API returns one attendance object per date with many "records", we map record entries separately at service layer
    return AttendanceRecord(
      id: (json['_id'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      lessonGroupName: lgName.toString(),
      studentId: '', // will be filled by service when mapping each student record
      studentName: '',
      status: '',
      comment: '',
    );
  }
}
