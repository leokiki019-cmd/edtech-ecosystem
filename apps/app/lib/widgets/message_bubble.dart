import 'package:edtech_app/models/chat_message.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isOwn;

  const MessageBubble({super.key, required this.message, required this.isOwn});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(widget.isOwn ? 0.3 : -0.3, 0.1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.isOwn
        ? livelyGradient(kPrimary, kPrimaryDark)
        : null;

    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: widget.isOwn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: bubbleColor,
              color: widget.isOwn ? null : kSurface,
              border: widget.isOwn ? null : Border.all(color: kBorder),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: widget.isOwn ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight: widget.isOwn ? const Radius.circular(4) : const Radius.circular(18),
              ),
              boxShadow: widget.isOwn
                  ? [
                      BoxShadow(
                        color: kPrimary.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.body,
                  style: TextStyle(
                    color: widget.isOwn ? Colors.white : kTextPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.message.authorId}  ·  ${_formatTime(widget.message.sentAt)}',
                  style: TextStyle(
                    color: widget.isOwn ? Colors.white.withValues(alpha: 0.7) : kTextSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
