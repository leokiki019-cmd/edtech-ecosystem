import 'package:flutter/material.dart';

class ErrorCard extends StatelessWidget {
  final String message;
  const ErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFEF2F2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
        ),
      ),
    );
  }
}
