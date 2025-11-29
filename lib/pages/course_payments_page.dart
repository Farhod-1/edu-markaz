import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/lesson_group.dart';
import '../models/payment.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../services/lesson_group_service.dart';
import '../services/payment_service.dart';

class CoursePaymentsPage extends StatefulWidget {
  const CoursePaymentsPage({super.key});

  @override
  State<CoursePaymentsPage> createState() => _CoursePaymentsPageState();
}

class _CoursePaymentsPageState extends State<CoursePaymentsPage> {
  final CourseService _courseService = CourseService();
  final PaymentService _paymentService = PaymentService();
  final LessonGroupService _lessonGroupService = LessonGroupService();
  final AuthService _authService = AuthService();
  
  List<Course> _courses = [];
  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0; // 0 = Courses, 1 = My Payments
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final user = await _authService.getUser();
    setState(() {
      _currentUser = user;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courses = await _courseService.getCourses();
      final payments = await _paymentService.getUserPayments();
      
      if (mounted) {
        setState(() {
          _courses = courses;
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makePayment(Course course) async {
    // Get student ID from user's children or use user ID
    String? studentId;
    
    if (_currentUser != null) {
      if (_currentUser!.children.isNotEmpty) {
        // Use first child's ID if available
        final firstChild = _currentUser!.children.first;
        if (firstChild is Map<String, dynamic>) {
          studentId = firstChild['_id'] as String? ?? firstChild['id'] as String?;
        } else if (firstChild is String) {
          studentId = firstChild;
        }
      }
      
      // If no children, use user ID as fallback
      if (studentId == null || studentId.isEmpty) {
        studentId = _currentUser!.id;
      }
    }

    if (studentId == null || studentId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Student ID not found. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Load lesson groups for this course
    List<LessonGroup> lessonGroups = [];
    try {
      lessonGroups = await _lessonGroupService.getLessonGroups(courseId: course.id);
    } catch (e) {
      // If we can't load groups, continue without them
    }

    // Show dialog to select lesson group if available
    String? selectedLessonGroupId;
    if (lessonGroups.isNotEmpty) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Lesson Group'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: lessonGroups.length,
              itemBuilder: (context, index) {
                final group = lessonGroups[index];
                return ListTile(
                  title: Text(group.name),
                  subtitle: Text(group.schedule ?? 'No schedule'),
                  trailing: group.isFull
                      ? const Chip(label: Text('Full'), backgroundColor: Colors.orange)
                      : null,
                  onTap: () => Navigator.of(context).pop(group.id),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (result == null) return; // User cancelled
      selectedLessonGroupId = result;
    }

    // Select month for payment (format: YYYY-MM)
    DateTime? selectedMonth;
    final now = DateTime.now();
    
    final monthResult = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Month'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Year selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      // This would need state management - for now use current year
                    },
                  ),
                  Text(
                    '${now.year}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      // This would need state management - for now use current year
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Month grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final date = DateTime(now.year, month);
                    final monthNames = [
                      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                    ];
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(date),
                      child: Card(
                        elevation: 2,
                        child: Center(
                          child: Text(
                            monthNames[index],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (monthResult == null) return; // User cancelled
    selectedMonth = monthResult;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'Pay ${course.price.toStringAsFixed(2)} UZS for ${course.name}?'
          '\n\nMonth: ${_formatMonth(selectedMonth!)}'
          '${selectedLessonGroupId != null ? '\nSelected group: ${lessonGroups.firstWhere((g) => g.id == selectedLessonGroupId).name}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Format month as "YYYY-MM" string (e.g., "2024-03")
      final monthString = '${selectedMonth!.year}-${selectedMonth!.month.toString().padLeft(2, '0')}';
      
      // Verify lesson group exists in backend before using it
      String? verifiedLessonGroupId = selectedLessonGroupId;
      if (selectedLessonGroupId != null && selectedLessonGroupId.isNotEmpty) {
        try {
          final group = await _lessonGroupService.getLessonGroupById(selectedLessonGroupId);
          if (group == null) {
            // Lesson group doesn't exist in backend (likely from mock data)
            verifiedLessonGroupId = null;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note: Selected lesson group not found in system. Payment will be created without lesson group assignment.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          // If we can't verify, don't send the lessonGroupId to avoid backend errors
          verifiedLessonGroupId = null;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note: Could not verify lesson group. Payment will be created without lesson group assignment.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // lessonGroupId is null or empty, which is fine
        verifiedLessonGroupId = null;
      }
      
      await _paymentService.createPayment(
        courseId: course.id,
        amount: course.price,
        studentId: studentId,
        month: monthString,
        lessonGroupId: verifiedLessonGroupId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment initiated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(0, 'Courses', Icons.school),
                ),
                Expanded(
                  child: _buildTabButton(1, 'My Payments', Icons.payment),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _selectedTab == 0
                        ? _buildCoursesList()
                        : _buildPaymentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No courses available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return _buildCourseCard(course);
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _makePayment(course),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.school,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (course.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            course.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: course.status == 'active'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      course.status.toUpperCase(),
                      style: TextStyle(
                        color: course.status == 'active' ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${course.price.toStringAsFixed(0)} UZS',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _makePayment(course),
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsList() {
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No payments found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (context, index) {
          final payment = _payments[index];
          return _buildPaymentCard(payment);
        },
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    Color statusColor;
    IconData statusIcon;
    final isPending = payment.status.toLowerCase() == 'pending';
    
    switch (payment.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPending ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isPending ? () => _payRemainingAmount(payment) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.courseName ?? 'Course Payment',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(payment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          payment.statusDisplay,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${payment.amount.toStringAsFixed(0)} UZS',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              if (payment.transactionId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Transaction ID: ${payment.transactionId}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
              if (isPending) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payment, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap to pay remaining amount',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.blue[700], size: 16),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatMonth(DateTime date) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  Future<void> _payRemainingAmount(Payment payment) async {
    // Get the course to know the total price
    Course? course;
    try {
      final courses = await _courseService.getCourses();
      try {
        course = courses.firstWhere((c) => c.id == payment.courseId);
      } catch (e) {
        // Course not found in list
        course = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (course == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course not found. Using payment amount as total.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        // Use a default total amount if course not found
        // In this case, we'll just allow paying any amount
      }
    }

    // Calculate remaining amount (assuming payment.amount is what's been paid)
    // If the backend tracks this differently, we might need to adjust
    final totalAmount = course?.price ?? payment.amount * 2; // Default to 2x if course not found
    final paidAmount = payment.amount;
    final remainingAmount = (totalAmount - paidAmount).clamp(0.0, double.infinity);

    // Show dialog to enter payment amount
    final amountController = TextEditingController(
      text: (course != null && remainingAmount > 0) ? remainingAmount.toStringAsFixed(0) : '',
    );
    bool payRemaining = course != null && remainingAmount > 0;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pay Remaining Amount'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course: ${course?.name ?? payment.courseName ?? 'Course Payment'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (course != null) ...[
                  Text('Total Amount: ${totalAmount.toStringAsFixed(0)} UZS'),
                  Text('Paid Amount: ${paidAmount.toStringAsFixed(0)} UZS'),
                  Text(
                    'Remaining: ${remainingAmount.toStringAsFixed(0)} UZS',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ] else ...[
                  Text('Paid Amount: ${paidAmount.toStringAsFixed(0)} UZS'),
                  Text(
                    'Enter amount to pay:',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (course != null && remainingAmount > 0)
                  CheckboxListTile(
                    title: const Text('Pay remaining amount'),
                    value: payRemaining,
                    onChanged: (value) {
                      setDialogState(() {
                        payRemaining = value ?? true;
                        if (payRemaining) {
                          amountController.text = remainingAmount > 0
                              ? remainingAmount.toStringAsFixed(0)
                              : '';
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  enabled: course == null || !payRemaining,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount (UZS)',
                    border: OutlineInputBorder(),
                    prefixText: '',
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (remainingAmount <= 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: This payment appears to be fully paid.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amountText = amountController.text.trim();
                if (amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop({
                  'amount': amount,
                });
              },
              child: const Text('Pay'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final paymentAmount = result['amount'] as double;

    // Get student ID
    String? studentId;
    if (_currentUser != null) {
      if (_currentUser!.children.isNotEmpty) {
        final firstChild = _currentUser!.children.first;
        if (firstChild is Map<String, dynamic>) {
          studentId = firstChild['_id'] as String? ?? firstChild['id'] as String?;
        } else if (firstChild is String) {
          studentId = firstChild;
        }
      }
      if (studentId == null || studentId.isEmpty) {
        studentId = _currentUser!.id;
      }
    }

    if (studentId == null || studentId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Student ID not found. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Confirm payment
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'Pay ${paymentAmount.toStringAsFixed(0)} UZS for ${course?.name ?? payment.courseName ?? 'this course'}?'
          '\n\nThis will be added to your existing payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get current month for the payment
      final now = DateTime.now();
      final monthString = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Create a new payment for the additional amount
      await _paymentService.createPayment(
        courseId: payment.courseId,
        amount: paymentAmount,
        studentId: studentId,
        month: monthString,
        lessonGroupId: null, // Don't send lessonGroupId for additional payments
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ${paymentAmount.toStringAsFixed(0)} UZS initiated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

