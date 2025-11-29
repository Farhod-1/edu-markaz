import 'package:flutter/material.dart';
import '../services/user_service.dart';

class CreateUserModal extends StatefulWidget {
  final String? fixedRole;
  final Map<String, dynamic>? userToEdit;

  const CreateUserModal({
    super.key,
    this.fixedRole,
    this.userToEdit,
  });

  @override
  State<CreateUserModal> createState() => _CreateUserModalState();
}

class _CreateUserModalState extends State<CreateUserModal> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _role = 'STUDENT';
  String _status = 'ACTIVE';
  bool _isLoading = false;
  bool _passwordVisible = false;
  String _error = '';

  final List<String> _roles = ['STUDENT', 'TEACHER', 'ADMIN', 'OWNER', 'PARENT'];
  final List<String> _statuses = ['ACTIVE', 'INACTIVE'];

  @override
  void initState() {
    super.initState();
    if (widget.userToEdit != null) {
      _nameController.text = widget.userToEdit!['name'] ?? '';
      _phoneController.text = widget.userToEdit!['phoneNumber'] ?? '';
      _role = widget.userToEdit!['role'] ?? 'STUDENT';
      _status = widget.userToEdit!['status'] ?? 'ACTIVE';
    } else if (widget.fixedRole != null) {
      _role = widget.fixedRole!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final userData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'role': _role,
        'status': _status,
        if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
      };

      bool success;
      if (widget.userToEdit != null) {
        final userId = widget.userToEdit!['id'] ?? widget.userToEdit!['_id'];
        success = await _userService.updateUser(userId, userData);
      } else {
        success = await _userService.createUser(userData);
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.userToEdit != null ? 'User updated successfully' : 'User created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = 'Failed to ${widget.userToEdit != null ? "update" : "create"} user';
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
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
                      Text(
                        widget.userToEdit != null ? 'Edit User' : 'Create User',
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

                  // Name Field
                  _buildLabel('Name'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter user name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone Number Field
                  _buildLabel('Phone Number'),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      hintText: '+998940871218',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Color(0xFFF5F7FA),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Role Field
                  if (widget.fixedRole == null) ...[
                    _buildLabel('Role'),
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(_formatRole(role)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _role = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Status Field
                  _buildLabel('Status'),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_formatStatus(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  _buildLabel('Password', required: widget.userToEdit == null),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      hintText: widget.userToEdit != null ? 'Leave empty to keep current password' : '••••••••',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (v) {
                      if (widget.userToEdit == null && (v == null || v.isEmpty)) {
                        return 'Password is required';
                      }
                      if (v != null && v.isNotEmpty && v.length < 8) {
                        return 'Minimum 8 characters required';
                      }
                      return null;
                    },
                  ),
                  if (widget.userToEdit == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        'Minimum 8 characters required',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
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
                            : Text(widget.userToEdit != null ? 'Update' : 'Create'),
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

  String _formatRole(String role) {
    return role.substring(0, 1) + role.substring(1).toLowerCase();
  }

  String _formatStatus(String status) {
    return status.substring(0, 1) + status.substring(1).toLowerCase();
  }
}
