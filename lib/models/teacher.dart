import 'user.dart';

class Teacher {
  final User user;

  Teacher({required this.user});

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(user: User.fromJson(json));
  }

  String get id => user.id;
  String get phoneNumber => user.phoneNumber;
  String get status => user.status;
  DateTime get createdAt => user.createdAt;
  
  // Placeholder for name if it becomes available, otherwise use phone
  String get name => user.phoneNumber; 
}
