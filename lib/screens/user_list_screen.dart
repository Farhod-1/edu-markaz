import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'create_user_screen.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();
  List<User> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  String _error = '';
  String? _selectedRole;

  final List<String> _roles = ['STUDENT', 'TEACHER', 'ADMIN', 'OWNER', 'PARENT'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
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
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final newUsers = await _userService.getUsers(page: _page, role: _selectedRole);
      setState(() {
        _users.addAll(newUsers);
        _page++;
        if (newUsers.isEmpty) {
          _hasMore = false;
        }
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
      _users.clear();
      _page = 1;
      _hasMore = true;
      _error = '';
    });
    await _fetchUsers();
  }

  void _onRoleChanged(String? role) {
    if (_selectedRole == role) return;
    setState(() {
      _selectedRole = role;
    });
    _refresh();
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.phoneNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userService.deleteUser(user.id);
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
        title: const Text('Users'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _onRoleChanged,
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: null,
                  child: Text('All'),
                ),
                ..._roles.map((role) => PopupMenuItem(
                      value: role,
                      child: Text(role),
                    )),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final success = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateUserScreen()),
          );
          if (success == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error.isNotEmpty && _users.isEmpty
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
            : Column(
                children: [
                  if (_selectedRole != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Chip(
                        label: Text('Role: $_selectedRole'),
                        onDeleted: () => _onRoleChanged(null),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == _users.length) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ));
                        }

                        final user = _users[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(user.phoneNumber.length > 4 
                                ? user.phoneNumber.substring(user.phoneNumber.length - 2) 
                                : 'U'),
                            ),
                            title: Text(user.name.isNotEmpty ? user.name : user.phoneNumber),
                            subtitle: Text('${user.phoneNumber}\nRole: ${user.role}\nStatus: ${user.status}'),
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
                                        builder: (_) => UserDetailScreen(user: user),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () async {
                                    final success = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CreateUserScreen(userToEdit: user),
                                      ),
                                    );
                                    if (success == true) _refresh();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(user),
                                ),
                              ],
                            ),
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
}
