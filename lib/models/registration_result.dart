class RegistrationResult {
  const RegistrationResult({
    required this.email,
    required this.message,
    required this.status,
  });

  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    return RegistrationResult(
      email: json['email'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_approval',
    );
  }

  final String email;
  final String message;
  final String status;
}
