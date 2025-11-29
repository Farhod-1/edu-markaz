import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  bool _loading = true;
  List<User> _students = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final students = await _userService.getStudents();
      setState(() {
        _students = students;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text('Error: $_error'));
    if (_students.isEmpty)
      return const Center(child: Text('No students found'));

    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        child: ListView.separated(
          itemCount: _students.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final s = _students[i];
            return ListTile(
              title: Text(s.name.isNotEmpty ? s.name : s.phoneNumber),
              subtitle: Text('${s.phoneNumber} • ${s.status}'),
              trailing: Text(s.role),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => UserDetailScreen(user: s),
                ));
              },
            );
          },
        ),
      ),
    );
  }
}
