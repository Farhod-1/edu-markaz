import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/lesson_group.dart';
import '../services/course_service.dart';
import '../services/lesson_group_service.dart';

class CreateEditLessonGroupPage extends StatefulWidget {
  final LessonGroup? group; // If null, create new; if provided, edit existing

  const CreateEditLessonGroupPage({
    super.key,
    this.group,
  });

  @override
  State<CreateEditLessonGroupPage> createState() =>
      _CreateEditLessonGroupPageState();
}

class _CreateEditLessonGroupPageState extends State<CreateEditLessonGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _maxStudentsController = TextEditingController();

  final CourseService _courseService = CourseService();
  final LessonGroupService _lessonGroupService = LessonGroupService();

  List<Course> _courses = [];
  Course? _selectedCourse;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    if (widget.group != null) {
      _loadGroupData();
    }
    _selectedStatus = widget.group?.status ?? 'active';
  }

  void _loadGroupData() {
    final group = widget.group!;
    _nameController.text = group.name;
    _descriptionController.text = group.description ?? '';
    _scheduleController.text = group.schedule ?? '';
    _maxStudentsController.text = group.maxStudents?.toString() ?? '';
    _startDate = group.startDate;
    _endDate = group.endDate;
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await _courseService.getCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          if (widget.group != null) {
            _selectedCourse = courses.firstWhere(
              (c) => c.id == widget.group!.courseId,
              orElse: () => courses.isNotEmpty ? courses.first : courses.first,
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.group == null) {
        // Create new
        await _lessonGroupService.createLessonGroup({
          'name': _nameController.text.trim(),
          'courseId': _selectedCourse!.id,
          if (_descriptionController.text.trim().isNotEmpty)
            'description': _descriptionController.text.trim(),
          if (_maxStudentsController.text.trim().isNotEmpty)
            'maxStudents': int.tryParse(_maxStudentsController.text.trim()),
          if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
          if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
          if (_scheduleController.text.trim().isNotEmpty)
            'schedule': _scheduleController.text.trim(),
        });
      } else {
        // Update existing
        await _lessonGroupService.updateLessonGroup(
          widget.group!.id,
          {
            'name': _nameController.text.trim(),
            'courseId': _selectedCourse!.id,
            if (_descriptionController.text.trim().isNotEmpty)
              'description': _descriptionController.text.trim(),
            if (_maxStudentsController.text.trim().isNotEmpty)
              'maxStudents': int.tryParse(_maxStudentsController.text.trim()),
            if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
            if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
            if (_scheduleController.text.trim().isNotEmpty)
              'schedule': _scheduleController.text.trim(),
            'status': _selectedStatus,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.group == null
                ? 'Lesson group created successfully'
                : 'Lesson group updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scheduleController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.group == null ? 'Create Lesson Group' : 'Edit Lesson Group'),
        actions: [
          if (widget.group != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteGroup(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Course Selection
                    DropdownButtonFormField<Course>(
                      value: _selectedCourse,
                      decoration: const InputDecoration(
                        labelText: 'Course *',
                        border: OutlineInputBorder(),
                      ),
                      items: _courses.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text(course.name),
                        );
                      }).toList(),
                      onChanged: (course) {
                        setState(() {
                          _selectedCourse = course;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a course';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a group name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Schedule
                    TextFormField(
                      controller: _scheduleController,
                      decoration: const InputDecoration(
                        labelText:
                            'Schedule (e.g., Monday, Wednesday - 9:00 AM)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Max Students
                    TextFormField(
                      controller: _maxStudentsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Students',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Start Date
                    InkWell(
                      onTap: () => _selectDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Select start date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End Date
                    InkWell(
                      onTap: () => _selectDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Select end date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status (only for editing)
                    if (widget.group != null) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'active', child: Text('Active')),
                          DropdownMenuItem(
                              value: 'inactive', child: Text('Inactive')),
                          DropdownMenuItem(value: 'full', child: Text('Full')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.group == null
                              ? 'Create Group'
                              : 'Update Group'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson Group'),
        content: const Text(
            'Are you sure you want to delete this lesson group? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _lessonGroupService.deleteLessonGroup(widget.group!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson group deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting group: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
