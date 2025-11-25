import 'package:flutter/material.dart';
import '../models/user.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    child: Text(
                      user.phoneNumber.length > 4
                          ? user.phoneNumber.substring(user.phoneNumber.length - 2)
                          : 'U',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Phone Number', user.phoneNumber),
                const Divider(),
                _buildDetailRow('Role', user.role),
                const Divider(),
                _buildDetailRow('Status', user.status),
                const Divider(),
                _buildDetailRow('Language', user.language),
                const Divider(),
                _buildDetailRow('Created At', user.createdAt.toString().split('.')[0]),
                if (user.telegramChatId != null) ...[
                  const Divider(),
                  _buildDetailRow('Telegram Chat ID', user.telegramChatId!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
