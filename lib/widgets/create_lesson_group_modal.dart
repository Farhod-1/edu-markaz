import 'package:flutter/material.dart';
import '../models/lesson_group.dart';
import '../models/course.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../services/lesson_group_service.dart';
import '../services/course_service.dart';
import '../services/room_service.dart';
import '../services/user_service.dart';

class CreateLessonGroupModal extends StatefulWidget {
  final LessonGroup? groupToEdit;

  const CreateLessonGroupModal({super.key, this.groupToEdit});

  @override
  State<CreateLessonGroupModal> createState() => _CreateLessonGroupModalState();
}

class _CreateLessonGroupModalState extends State<CreateLessonGroupModal> {
  final _formKey = GlobalKey<FormState>();
  final _lessonGroupService = LessonGroupService();
  final _courseService = CourseService();
  final _roomService = RoomService();
  final _userService = UserService();

  final _nameController = TextEditingController();
  
  List<Course> _courses = [];
  List<Room> _rooms = [];
  List<User> _teachers = [];
  List<User> _students = [];
  
  String? _selectedCourseId;
  String? _selectedRoomId;
  String? _selectedTeacherId;
  final List<String> _selectedStudentIds = [];
  final List<String> _selectedDays = [];

  bool _isLoading = false;
  bool _isInitLoading = true;
  String _error = '';

  final List<String> _weekDays = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isInitLoading = true);
    try {
      final courses = await _courseService.getAllCourses();
      final rooms = await _roomService.getRooms();
      final teachers = await _userService.getUsers(role: 'TEACHER', limit: 100);
      final students = await _userService.getUsers(role: 'STUDENT', limit: 100);

      if (mounted) {
        setState(() {
          _courses = courses;
          _rooms = rooms;
          _teachers = teachers;
          _students = students;
          
          if (widget.groupToEdit != null) {
            _nameController.text = widget.groupToEdit!.name;
            _selectedCourseId = widget.groupToEdit!.courseId;
            // _selectedRoomId = widget.groupToEdit!.roomId; // Assuming LessonGroup has roomId
            _selectedDays.addAll(widget.groupToEdit!.days.map((e) => e.toLowerCase()));
            
            // Map student IDs
            for (var s in widget.groupToEdit!.studentIds) {
              final id = s['_id'] ?? s['id'];
              if (id != null) {
                _selectedStudentIds.add(id.toString());
              }
            }
          }
          
          _isInitLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isInitLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final groupData = {
        'name': _nameController.text.trim(),
        'days': _selectedDays,
        if (_selectedCourseId != null) 'courseId': _selectedCourseId,
        if (_selectedRoomId != null) 'roomId': _selectedRoomId,
        if (_selectedTeacherId != null) 'teacherId': _selectedTeacherId,
        'studentIds': _selectedStudentIds,
      };

      if (widget.groupToEdit != null) {
        await _lessonGroupService.updateLessonGroup(widget.groupToEdit!.id, groupData);
      } else {
        await _lessonGroupService.createLessonGroup(groupData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.groupToEdit != null ? 'Group updated successfully' : 'Group created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading data...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupToEdit != null ? 'Edit Lesson Group' : 'Create Lesson Group',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a new lesson group to your organization',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Group Name
                      _buildLabel('Group Name'),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter lesson group name',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 24),

                      // Schedule Days
                      _buildLabel('Schedule Days', required: false),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _weekDays.map((day) {
                          final isSelected = _selectedDays.contains(day);
                          return FilterChip(
                            label: Text(_capitalize(day)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDays.add(day);
                                } else {
                                  _selectedDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Resources Section
                      const Text(
                        'Resources',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Assign teacher, course, and room for this group',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Teacher', required: false),
                                DropdownButtonFormField<String>(
                                  value: _selectedTeacherId,
                                  decoration: const InputDecoration(
                                    hintText: 'Select a teacher (optional)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  items: _teachers.map((t) => DropdownMenuItem(
                                    value: t.id,
                                    child: Text(t.name.isNotEmpty ? t.name : t.phoneNumber),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _selectedTeacherId = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Course', required: false),
                                DropdownButtonFormField<String>(
                                  value: _selectedCourseId,
                                  decoration: const InputDecoration(
                                    hintText: 'Select a course (optional)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  items: _courses.map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _selectedCourseId = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildLabel('Room', required: false),
                      DropdownButtonFormField<String>(
                        value: _selectedRoomId,
                        decoration: const InputDecoration(
                          hintText: 'Select a room (optional)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: _rooms.map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text('${r.name} (Cap: ${r.capacity})'),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedRoomId = v),
                      ),
                      const SizedBox(height: 24),

                      // Students Section
                      const Text(
                        'Students',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        height: 200,
                        child: ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final isSelected = _selectedStudentIds.contains(student.id);
                            return CheckboxListTile(
                              title: Text(student.name.isNotEmpty ? student.name : student.phoneNumber),
                              subtitle: Text(student.phoneNumber),
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedStudentIds.add(student.id);
                                  } else {
                                    _selectedStudentIds.remove(student.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.groupToEdit != null ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
