import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/course_payment.dart';
import '../models/lesson_group.dart';
import '../services/course_payment_service.dart';
import '../services/lesson_group_service.dart';
import '../widgets/create_course_payment_modal.dart';

class CoursePaymentsScreen extends StatefulWidget {
  const CoursePaymentsScreen({super.key});

  @override
  State<CoursePaymentsScreen> createState() => _CoursePaymentsScreenState();
}

class _CoursePaymentsScreenState extends State<CoursePaymentsScreen> {
  final CoursePaymentService _paymentService = CoursePaymentService();
  final LessonGroupService _lessonGroupService = LessonGroupService();
  
  List<CoursePayment> _payments = [];
  List<LessonGroup> _lessonGroups = [];
  Map<String, dynamic> _paymentSummary = {};
  
  bool _isLoading = false;
  String _error = '';
  
  // Filters
  String _searchQuery = '';
  String? _selectedLessonGroupId;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadLessonGroups();
    _fetchPayments();
  }

  Future<void> _loadLessonGroups() async {
    try {
      final groups = await _lessonGroupService.getLessonGroups(limit: 100);
      setState(() {
        _lessonGroups = groups;
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _fetchPayments() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final result = await _paymentService.getCoursePayments(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        lessonGroupId: _selectedLessonGroupId,
        month: _selectedMonth,
        page: _currentPage,
        limit: 10,
      );

      final payments = result['payments'] as List<CoursePayment>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      // Calculate summary
      final summary = _calculateSummary(payments);

      setState(() {
        if (_currentPage == 1) {
          _payments = payments;
        } else {
          _payments.addAll(payments);
        }
        _paymentSummary = summary;
        _hasMore = pagination['hasNext'] as bool? ?? false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateSummary(List<CoursePayment> payments) {
    final groupedByStudent = <String, Map<String, dynamic>>{};
    
    for (final payment in payments) {
      if (!groupedByStudent.containsKey(payment.studentId)) {
        groupedByStudent[payment.studentId] = {
          'studentName': payment.studentName,
          'studentPhone': payment.studentPhone,
          'totalAmount': 0,
          'paymentCount': 0,
        };
      }
      
      groupedByStudent[payment.studentId]!['totalAmount'] = 
          (groupedByStudent[payment.studentId]!['totalAmount'] as int) + payment.amount;
      groupedByStudent[payment.studentId]!['paymentCount'] = 
          (groupedByStudent[payment.studentId]!['paymentCount'] as int) + 1;
    }
    
    return {'students': groupedByStudent};
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    await _fetchPayments();
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 1;
      _payments.clear();
      _hasMore = true;
    });
    _fetchPayments();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedLessonGroupId = null;
      _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
      _currentPage = 1;
      _payments.clear();
      _hasMore = true;
    });
    _fetchPayments();
  }

  Future<void> _deletePayment(CoursePayment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Delete payment of ${NumberFormat.currency(symbol: 'UZS ', decimalDigits: 0).format(payment.amount)} for ${payment.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _paymentService.deletePayment(payment.id);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showCreatePaymentDialog([CoursePayment? payment]) {
    showDialog(
      context: context,
      builder: (context) => CreateCoursePaymentModal(
        paymentToEdit: payment,
        lessonGroups: _lessonGroups,
      ),
    ).then((success) {
      if (success == true) {
        _refresh();
      }
    });
  }

  void _showStudentPayments(String studentId, String studentName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StudentPaymentsDetailScreen(
          studentId: studentId,
          studentName: studentName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Payments'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLessonGroupId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Lesson Group',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Groups')),
                          ..._lessonGroups.map((group) => DropdownMenuItem(
                                value: group.id,
                                child: Text(group.name, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedLessonGroupId = value);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          suffixIcon: const Icon(Icons.calendar_month),
                        ),
                        controller: TextEditingController(text: _selectedMonth),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateFormat('yyyy-MM').parse(_selectedMonth),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedMonth = DateFormat('yyyy-MM').format(date);
                            });
                            _applyFilters();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Payment List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _error.isNotEmpty && _payments.isEmpty
                  ? _buildErrorState()
                  : _isLoading && _payments.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _payments.isEmpty
                          ? _buildEmptyState()
                          : _buildPaymentList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'course_payments_fab',
        onPressed: () => _showCreatePaymentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Payment'),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 24),
              Text(
                'No payments found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentList() {
    // Group by student for summary view
    final studentMap = _paymentSummary['students'] as Map<String, Map<String, dynamic>>? ?? {};

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: studentMap.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == studentMap.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _currentPage++);
                  _fetchPayments();
                },
                child: const Text('Load More'),
              ),
            ),
          );
        }

        final studentId = studentMap.keys.elementAt(index);
        final studentData = studentMap[studentId]!;
        final totalAmount = studentData['totalAmount'] as int;
        final paymentCount = studentData['paymentCount'] as int;
        
        final isPaid = totalAmount > 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              studentData['studentName'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(studentData['studentPhone'] as String),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPaid ? 'Paid: ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(totalAmount)} UZS' : 'Not Paid',
                        style: TextStyle(
                          color: isPaid ? Colors.green.shade900 : Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$paymentCount payment${paymentCount > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _showStudentPayments(studentId, studentData['studentName'] as String),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showCreatePaymentDialog(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Student Payments Detail Screen
class _StudentPaymentsDetailScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const _StudentPaymentsDetailScreen({
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final paymentService = CoursePaymentService();

    return Scaffold(
      appBar: AppBar(
        title: Text('$studentName - Payments'),
      ),
      body: FutureBuilder<List<CoursePayment>>(
        future: paymentService.getStudentPayments(studentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            return const Center(child: Text('No payments found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    NumberFormat.currency(symbol: 'UZS ', decimalDigits: 0).format(payment.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Group: ${payment.lessonGroupName}'),
                      Text('Month: ${payment.month}'),
                      if (payment.notes != null && payment.notes!.isNotEmpty)
                        Text('Notes: ${payment.notes}'),
                    ],
                  ),
                  trailing: Text(
                    DateFormat('MMM d, y').format(payment.createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
