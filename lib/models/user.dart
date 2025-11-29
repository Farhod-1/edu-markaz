class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String role;
  final String status;
  final List<dynamic> children;
  final String? telegramChatId;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.status,
    required this.children,
    this.telegramChatId,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      name: (json['name'] ?? json['fullName'] ?? '').toString(),
      phoneNumber: json['phoneNumber'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      children: json['children'] as List<dynamic>? ?? [],
      telegramChatId: json['telegramChatId'] as String?,
      language: json['language'] as String? ?? 'en',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'role': role,
      'status': status,
      'children': children,
      'telegramChatId': telegramChatId,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

