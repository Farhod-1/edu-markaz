class LessonGroup {
  final String id;
  final String name;
  final List<String> days;
  final String organizationName;
  final List<Map<String, dynamic>> studentIds; // minimal - contains id,name,phoneNumber

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
