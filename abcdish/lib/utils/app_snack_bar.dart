import 'package:flutter/material.dart';

const _successGreen = Color(0xFF2E7D32);
const _errorRed = Color(0xFFC62828);

SnackBar successSnackBar(String message) {
  return _themedSnackBar(
    message,
    backgroundColor: _successGreen,
    icon: Icons.check_circle_outline,
  );
}

SnackBar errorSnackBar(String message) {
  return _themedSnackBar(
    message,
    backgroundColor: _errorRed,
    icon: Icons.error_outline,
  );
}

SnackBar _themedSnackBar(
  String message, {
  required Color backgroundColor,
  required IconData icon,
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: backgroundColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    content: Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
