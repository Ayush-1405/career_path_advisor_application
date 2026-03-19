import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PasswordRequirementChecklist extends StatelessWidget {
  final String password;

  const PasswordRequirementChecklist({super.key, required this.password});

  bool get _hasMinLength => password.length >= 8;
  bool get _hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirementRow('At least 8 characters', _hasMinLength),
        _buildRequirementRow('One uppercase letter', _hasUppercase),
        _buildRequirementRow('One lowercase letter', _hasLowercase),
        _buildRequirementRow('One number', _hasNumber),
        _buildRequirementRow('One special character', _hasSpecial),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : AppTheme.gray400,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? AppTheme.gray700 : AppTheme.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
