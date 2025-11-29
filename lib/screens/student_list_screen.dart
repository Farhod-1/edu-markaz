import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/user.dart';
import '../services/student_service.dart';
import 'create_user_screen.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final StudentService _studentService = StudentService();
  final ScrollController _scrollController = ScrollController();
  List<Student> _students = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchStudents();
    }
  }

  Future<void> _fetchStudents() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final newStudents = await _studentService.getStudents(page: _page);
      print('Fetched ${newStudents.length} students for page $_page');
      setState(() {
        _students.addAll(newStudents);
        _page++;
        // If we got fewer items than the limit (50), we've reached the end
        if (newStudents.isEmpty || newStudents.length < 50) {
          _hasMore = false;
        }
      });
    } catch (e) {
      print('Error fetching students: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _students.clear();
      _page = 1;
      _hasMore = true;
      _error = '';
    });
    await _fetchStudents();
  }

  Future<void> _deleteStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // We can use UserService or StudentService. Since we added deleteStudent to StudentService, let's use that.
        // But wait, I added it to StudentService but I need to expose it here.
        // Actually, StudentService is used here.
        await _studentService.deleteStudent(student.id);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final success = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateUserScreen(fixedRole: 'STUDENT')),
          );
          if (success == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error.isNotEmpty && _students.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _isLoading && _students.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No students found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == _students.length) {
                            return const Center(child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ));
                          }

                          final student = _students[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?'),
                              ),
                              title: Text(student.name),
                              subtitle: Text('${student.phoneNumber}\nStatus: ${student.status}'),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentDetailScreen(
                                            studentId: student.id,
                                            studentName: student.name,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () async {
                                      // Convert Student to User for editing
                                      final userToEdit = User(
                                        id: student.id,
                                        name: student.name,
                                        phoneNumber: student.phoneNumber,
                                        role: student.role,
                                        status: student.status,
                                        children: [], // Students don't have children usually in this context
                                        language: 'en', // Default
                                        createdAt: student.createdAt,
                                        updatedAt: student.updatedAt,
                                      );
                                      
                                      final success = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateUserScreen(
                                            fixedRole: 'STUDENT',
                                            userToEdit: userToEdit,
                                          ),
                                        ),
                                      );
                                      if (success == true) _refresh();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteStudent(student),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
