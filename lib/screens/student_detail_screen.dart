import 'package:flutter/material.dart';
import '../services/student_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  const StudentDetailScreen({super.key, required this.studentId, required this.studentName});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final StudentService _svc = StudentService();
  bool _loading = true;
  List<Map<String, dynamic>> _attendance = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final attend = await _svc.getAttendanceForStudent(widget.studentId);
      setState(() { _attendance = attend; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.studentName.isNotEmpty ? widget.studentName : 'Student')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('Error: $_error'))
              : _attendance.isEmpty
                  ? const Center(child: Text('No attendance records'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _attendance.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final a = _attendance[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${a['lessonGroupName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('Date: ${a['date'] ?? ''}'),
                                Text('Status: ${a['status'] ?? ''}'),
                                if ((a['comment'] ?? '').toString().isNotEmpty) Text('Note: ${a['comment']}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
