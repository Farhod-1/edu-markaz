import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/user_service.dart';
import '../widgets/create_teacher_dialog.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final UserService _userService = UserService();
  List<Teacher> _teachers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teachers = await _userService.getTeachers();
      setState(() {
        _teachers = teachers;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load teachers';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => const CreateTeacherDialog(),
              );
              
              if (result == true) {
                _loadTeachers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teacher created successfully')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search teachers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    onChanged: (value) {
                      // TODO: Implement local search or API search
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // TODO: Implement filter
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            TextButton(
                              onPressed: _loadTeachers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _teachers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No teachers yet',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Get started by adding your first teacher.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => const CreateTeacherDialog(),
                                    );
                                    
                                    if (result == true) {
                                      _loadTeachers();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Teacher created successfully')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Your First Teacher'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _teachers.length,
                            itemBuilder: (context, index) {
                              final teacher = _teachers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : 'T'),
                                  ),
                                  title: Text(teacher.name),
                                  subtitle: Text(teacher.phoneNumber),
                                  trailing: Chip(
                                    label: Text(
                                      teacher.status,
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                    backgroundColor: teacher.status.toLowerCase() == 'active' 
                                        ? Colors.green 
                                        : Colors.grey,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
