import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/course_payment.dart';
import '../models/lesson_group.dart';
import '../models/user.dart';
import '../services/course_payment_service.dart';
import '../services/user_service.dart';

class CreateCoursePaymentModal extends StatefulWidget {
  final CoursePayment? paymentToEdit;
  final List<LessonGroup> lessonGroups;

  const CreateCoursePaymentModal({
    super.key,
    this.paymentToEdit,
    required this.lessonGroups,
  });

  @override
  State<CreateCoursePaymentModal> createState() =>
      _CreateCoursePaymentModalState();
}

class _CreateCoursePaymentModalState extends State<CreateCoursePaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final CoursePaymentService _paymentService = CoursePaymentService();
  final UserService _userService = UserService();

  String? _selectedStudentId;
  String? _selectedLessonGroupId;
  final _amountController = TextEditingController();
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final _notesController = TextEditingController();

  List<User> _students = [];
  bool _isLoading = false;
  bool _loadingStudents = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();

    if (widget.paymentToEdit != null) {
      _selectedStudentId = widget.paymentToEdit!.studentId;
      _selectedLessonGroupId = widget.paymentToEdit!.lessonGroupId;
      _amountController.text = widget.paymentToEdit!.amount.toString();
      _selectedMonth = widget.paymentToEdit!.month;
      _notesController.text = widget.paymentToEdit!.notes ?? '';
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final students = await _userService.getUsers(role: 'STUDENT', limit: 100);
      print('Loaded ${students.length} students');
      for (var student in students) {
        print('Student: ${student.name} - ${student.id}');
      }
      setState(() {
        _students = students;
      });
    } catch (e) {
      print('Error loading students: $e');
    } finally {
      setState(() => _loadingStudents = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStudentId == null) {
      setState(() => _error = 'Please select a student');
      return;
    }

    if (_selectedLessonGroupId == null) {
      setState(() => _error = 'Please select a lesson group');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final paymentData = {
        'studentId': _selectedStudentId,
        'lessonGroupId': _selectedLessonGroupId,
        'amount': int.tryParse(_amountController.text.trim()) ?? 0,
        'month': _selectedMonth,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      bool success;
      if (widget.paymentToEdit != null) {
        success = await _paymentService.updatePayment(
            widget.paymentToEdit!.id, paymentData);
      } else {
        success = await _paymentService.createPayment(paymentData);
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.paymentToEdit != null
                ? 'Payment updated successfully'
                : 'Payment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error =
              'Failed to ${widget.paymentToEdit != null ? "update" : "create"} payment';
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

  void _showStudentSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Student',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Student List
            Expanded(
              child: _loadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? const Center(
                          child: Text(
                            'No students found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _students.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final isSelected = _selectedStudentId == student.id;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              elevation: isSelected ? 4 : 1,
                              color: isSelected ? Colors.blue.shade50 : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  child: Icon(
                                    Icons.person,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                title: Text(
                                  student.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(student.phoneNumber),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.blue)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedStudentId = student.id;
                                    _error = '';
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.paymentToEdit != null
                              ? 'Edit Payment'
                              : 'Create Course Payment',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _error,
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Student Selector
                  _buildLabel('Student'),
                  GestureDetector(
                    onTap: widget.paymentToEdit != null
                        ? null
                        : () => _showStudentSelector(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedStudentId != null
                                  ? _students
                                      .firstWhere(
                                          (s) => s.id == _selectedStudentId)
                                      .name
                                  : 'Select student',
                              style: TextStyle(
                                color: _selectedStudentId != null
                                    ? Colors.black
                                    : Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down,
                              color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedStudentId == null && _error.contains('student'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        'Please select a student',
                        style:
                            TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Lesson Group Selector
                  _buildLabel('Lesson Group'),
                  DropdownButtonFormField<String>(
                    value: _selectedLessonGroupId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      prefixIcon: Icon(Icons.class_),
                    ),
                    hint: const Text('Select lesson group'),
                    items: widget.lessonGroups.map((group) {
                      return DropdownMenuItem(
                        value: group.id,
                        child: Text(group.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLessonGroupId = value;
                      });
                    },
                    validator: (v) =>
                        v == null ? 'Please select a lesson group' : null,
                  ),
                  const SizedBox(height: 20),

                  // Amount and Month Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Amount'),
                            TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                hintText: '0',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                prefixIcon: Icon(Icons.attach_money),
                                suffixText: 'UZS',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Amount is required';
                                if (int.tryParse(v) == null)
                                  return 'Invalid amount';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Month'),
                            TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                suffixIcon: Icon(Icons.calendar_month),
                              ),
                              controller:
                                  TextEditingController(text: _selectedMonth),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateFormat('yyyy-MM')
                                      .parse(_selectedMonth),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedMonth =
                                        DateFormat('yyyy-MM').format(date);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notes Field
                  _buildLabel('Notes', required: false),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Add payment notes...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(widget.paymentToEdit != null
                                ? 'Update'
                                : 'Create Payment'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
}
