import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/lesson_group.dart';
import '../services/attendance_service.dart';
import '../services/lesson_group_service.dart';
import '../widgets/create_attendance_modal.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final LessonGroupService _lessonGroupService = LessonGroupService();
  
  List<AttendanceRecord> _attendanceRecords = [];
  List<LessonGroup> _lessonGroups = [];
  bool _isLoading = false;
  String _error = '';
  
  // Filters
  String? _selectedLessonGroupId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadLessonGroups();
    _fetchAttendance();
  }

  Future<void> _loadLessonGroups() async {
    try {
      final groups = await _lessonGroupService.getLessonGroups(limit: 100);
      setState(() {
        _lessonGroups = groups;
      });
    } catch (e) {
      // Silently fail, lesson groups are optional for display
    }
  }

  Future<void> _fetchAttendance() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Calculate first and last day of selected month
      final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
      final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0);

      final result = await _attendanceService.getAttendanceRecords(
        lessonGroupId: _selectedLessonGroupId,
        fromDate: firstDay.toIso8601String().split('T')[0],
        toDate: lastDay.toIso8601String().split('T')[0],
        page: _currentPage,
        limit: 10,
      );

      final records = result['records'] as List<AttendanceRecord>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      setState(() {
        if (_currentPage == 1) {
          _attendanceRecords = records;
        } else {
          _attendanceRecords.addAll(records);
        }
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

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    await _fetchAttendance();
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 1;
      _attendanceRecords.clear();
      _hasMore = true;
    });
    _fetchAttendance();
  }

  void _clearFilters() {
    setState(() {
      _selectedLessonGroupId = null;
      _selectedMonth = DateTime.now().month;
      _selectedYear = DateTime.now().year;
      _currentPage = 1;
      _attendanceRecords.clear();
      _hasMore = true;
    });
    _fetchAttendance();
  }

  Future<void> _deleteAttendance(AttendanceRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: Text('Delete attendance for ${record.lessonGroupName} on ${DateFormat('MMM d, y').format(record.date)}?'),
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
        await _attendanceService.deleteAttendance(record.id);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance deleted successfully')),
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

  void _showCreateAttendanceDialog([AttendanceRecord? record]) {
    showDialog(
      context: context,
      builder: (context) => CreateAttendanceModal(
        attendanceToEdit: record,
        lessonGroups: _lessonGroups,
      ),
    ).then((success) {
      if (success == true) {
        _refresh();
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error.isNotEmpty && _attendanceRecords.isEmpty
            ? _buildErrorState()
            : _isLoading && _attendanceRecords.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _attendanceRecords.isEmpty
                    ? _buildEmptyState()
                    : _buildAttendanceList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAttendanceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Take Attendance'),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Attendance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lesson Group', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLessonGroupId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('All Groups'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Groups')),
                  ..._lessonGroups.map((group) => DropdownMenuItem(
                        value: group.id,
                        child: Text(group.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLessonGroupId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Month', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedMonth,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              const SizedBox(height: 16),
              const Text('Year', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
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
              Icon(Icons.fact_check_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 24),
              Text(
                'No attendance records found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendanceRecords.length + (_hasMore && !_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _attendanceRecords.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _currentPage++);
                  _fetchAttendance();
                },
                child: const Text('Load More'),
              ),
            ),
          );
        }

        final record = _attendanceRecords[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showCreateAttendanceDialog(record),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fact_check, color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.lessonGroupName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMM d, y').format(record.date),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showCreateAttendanceDialog(record);
                              break;
                            case 'delete':
                              _deleteAttendance(record);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 12),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      _buildStatChip(
                        'Present',
                        record.presentCount.toString(),
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Absent',
                        record.absentCount.toString(),
                        Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        'Late',
                        record.lateCount.toString(),
                        Colors.orange,
                      ),
                      const Spacer(),
                      Text(
                        '${record.totalStudents} total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (record.teacherName.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          record.teacherName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
