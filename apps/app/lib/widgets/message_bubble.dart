import 'package:edtech_app/models/chat_message.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOwn;

  const MessageBubble({super.key, required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOwn ? kPrimary : kSurface,
          border: isOwn ? null : Border.all(color: kBorder),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: isOwn ? const Radius.circular(14) : Radius.zero,
            bottomRight: isOwn ? Radius.zero : const Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: TextStyle(
                color: isOwn ? Colors.white : kTextPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.authorId}  ·  ${_formatTime(message.sentAt)}',
              style: TextStyle(
                color: isOwn ? Colors.white.withOpacity(0.7) : kTextSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
