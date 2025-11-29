import 'user.dart';

class Parent {
  final User user;

  Parent({required this.user});

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(user: User.fromJson(json));
  }

  String get id => user.id;
  String get phoneNumber => user.phoneNumber;
  String get status => user.status;
  List<dynamic> get children => user.children;
  DateTime get createdAt => user.createdAt;

  // Placeholder for name if it becomes available, otherwise use phone
  String get name => user.phoneNumber;
}
