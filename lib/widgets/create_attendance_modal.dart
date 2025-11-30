import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/lesson_group.dart';
import '../services/attendance_service.dart';

class CreateAttendanceModal extends StatefulWidget {
  final AttendanceRecord? attendanceToEdit;
  final List<LessonGroup> lessonGroups;

  const CreateAttendanceModal({
    super.key,
    this.attendanceToEdit,
    required this.lessonGroups,
  });

  @override
  State<CreateAttendanceModal> createState() => _CreateAttendanceModalState();
}

class _CreateAttendanceModalState extends State<CreateAttendanceModal> {
  final _formKey = GlobalKey<FormState>();
  final AttendanceService _attendanceService = AttendanceService();

  String? _selectedLessonGroupId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<AttendanceStudent> _students = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (widget.attendanceToEdit != null) {
      _selectedLessonGroupId = widget.attendanceToEdit!.lessonGroupId;
      _selectedMonth = widget.attendanceToEdit!.date.month;
      _selectedYear = widget.attendanceToEdit!.date.year;
      _students = widget.attendanceToEdit!.records.map((r) => r).toList();
    } else {
      _selectedMonth = DateTime.now().month;
      _selectedYear = DateTime.now().year;
    }
  }

  void _loadStudentsFromGroup() {
    if (_selectedLessonGroupId == null) return;

    final group = widget.lessonGroups.firstWhere(
      (g) => g.id == _selectedLessonGroupId,
      orElse: () => widget.lessonGroups.first,
    );

    if (widget.attendanceToEdit != null) return;

    setState(() {
      _students = group.studentIds.map((student) {
        return AttendanceStudent(
          studentId: student['_id'] as String? ?? student['id'] as String? ?? '',
          studentName: student['name'] as String? ?? 'Unknown',
          studentPhone: student['phoneNumber'] as String? ?? '',
          status: 'absent',
          comment: '',
        );
      }).toList();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLessonGroupId == null) {
      setState(() {
        _error = 'Please select a lesson group';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Use first day of selected month
      final selectedDate = DateTime(_selectedYear, _selectedMonth, 1);
      
      final attendanceData = {
        'lessonGroupId': _selectedLessonGroupId,
        'date': selectedDate.toIso8601String().split('T')[0],
        'records': _students.map((s) => s.toJson()).toList(),
      };

      bool success;
      if (widget.attendanceToEdit != null) {
        success = await _attendanceService.updateAttendance(
          widget.attendanceToEdit!.id,
          attendanceData,
        );
      } else {
        success = await _attendanceService.createAttendance(attendanceData);
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.attendanceToEdit != null
                ? 'Attendance updated successfully'
                : 'Attendance created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = 'Failed to ${widget.attendanceToEdit != null ? "update" : "create"} attendance';
        });
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


  void _updateStudentStatus(int index, String status) {
    setState(() {
      _students[index] = _students[index].copyWith(status: status);
    });
  }

  void _markAllPresent() {
    setState(() {
      _students = _students.map((s) => s.copyWith(status: 'present')).toList();
    });
  }

  void _markAllAbsent() {
    setState(() {
      _students = _students.map((s) => s.copyWith(status: 'absent')).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Text(
                    widget.attendanceToEdit != null ? 'Edit Attendance' : 'Take Attendance',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error Message
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

                        // Lesson Group Selector
                        _buildLabel('Lesson Group'),
                        DropdownButtonFormField<String>(
                          value: _selectedLessonGroupId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          hint: const Text('Select lesson group'),
                          items: widget.lessonGroups.map((group) {
                            return DropdownMenuItem(
                              value: group.id,
                              child: Text(group.name),
                            );
                          }).toList(),
                          onChanged: widget.attendanceToEdit != null
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedLessonGroupId = value;
                                  });
                                  _loadStudentsFromGroup();
                                },
                          validator: (v) => v == null ? 'Please select a lesson group' : null,
                        ),
                        const SizedBox(height: 20),

                        // Month Selector
                        _buildLabel('Month'),
                        DropdownButtonFormField<int>(
                          value: _selectedMonth,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: List.generate(12, (index) {
                            final month = index + 1;
                            final monthName = DateFormat.MMMM().format(DateTime(2000, month));
                            return DropdownMenuItem(
                              value: month,
                              child: Text(monthName),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              _selectedMonth = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Year Selector
                        _buildLabel('Year'),
                        DropdownButtonFormField<int>(
                          value: _selectedYear,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: List.generate(10, (index) {
                            final year = DateTime.now().year - index;
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              _selectedYear = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Students Section
                        Row(
                          children: [
                            _buildLabel('Students (${_students.length})'),
                            const Spacer(),
                            Flexible(
                              child: TextButton.icon(
                                onPressed: _markAllPresent,
                                icon: const Icon(Icons.check_circle, size: 16),
                                label: const Text('Present', style: TextStyle(fontSize: 11)),
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: TextButton.icon(
                                onPressed: _markAllAbsent,
                                icon: const Icon(Icons.cancel, size: 16),
                                label: const Text('Absent', style: TextStyle(fontSize: 11)),
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (_students.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Select a lesson group to load students',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          )
                        else
                          ..._students.asMap().entries.map((entry) {
                            final index = entry.key;
                            final student = entry.value;
                            return _buildStudentRow(index, student);
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Action Buttons
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
                        : Text(widget.attendanceToEdit != null ? 'Update' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentRow(int index, AttendanceStudent student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (student.studentPhone.isNotEmpty)
                  Text(
                    student.studentPhone,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildStatusButton(index, student, 'present', Colors.green, Icons.check_circle),
          const SizedBox(width: 4),
          _buildStatusButton(index, student, 'late', Colors.orange, Icons.access_time),
          const SizedBox(width: 4),
          _buildStatusButton(index, student, 'absent', Colors.red, Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    int index,
    AttendanceStudent student,
    String status,
    Color color,
    IconData icon,
  ) {
    final isSelected = student.status == status;
    return IconButton(
      onPressed: () => _updateStudentStatus(index, status),
      icon: Icon(icon),
      color: isSelected ? Colors.white : color,
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}
