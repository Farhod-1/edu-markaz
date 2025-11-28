class Payment {
  final String id;
  final String courseId;
  final String? courseName;
  final String userId;
  final double amount;
  final String status; // pending, completed, failed, cancelled
  final String? paymentMethod;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.courseId,
    this.courseName,
    required this.userId,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] as String? ?? json['id'] as String,
      courseId: json['courseId'] as String? ?? json['course_id'] as String,
      courseName: json['courseName'] as String?,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? json['payment_method'] as String?,
      transactionId: json['transactionId'] as String? ?? json['transaction_id'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'courseId': courseId,
      'courseName': courseName,
      'userId': userId,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

