import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user.dart';

class CreateUserScreen extends StatefulWidget {
  final String? fixedRole;
  final User? userToEdit;

  const CreateUserScreen({super.key, this.fixedRole, this.userToEdit});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'STUDENT';
  bool _isLoading = false;
  String _error = '';

  final List<String> _roles = ['STUDENT', 'TEACHER', 'ADMIN', 'OWNER', 'PARENT'];

  @override
  void initState() {
    super.initState();
    if (widget.userToEdit != null) {
      _nameController.text = widget.userToEdit!.name;
      _phoneController.text = widget.userToEdit!.phoneNumber;
      _role = widget.userToEdit!.role;
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
      if (widget.userToEdit != null) {
        await _userService.updateUser(widget.userToEdit!.id, {
          'phoneNumber': _phoneController.text,
          'role': _role,
          'name': _nameController.text,
          if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
        });
      } else {
        await _userService.createUser(
          _phoneController.text,
          _passwordController.text,
          _role,
          _nameController.text,
        );
      }
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userToEdit != null 
          ? 'Edit User' 
          : (widget.fixedRole != null ? 'Create ${widget.fixedRole}' : 'Create User')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Text(_error, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              if (widget.userToEdit == null) ...[
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ] else ...[
                 TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'New Password (Optional)'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
              ],
              if (widget.fixedRole == null)
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _role = v);
                  },
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.userToEdit != null ? 'Update' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
