import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/models/channel.dart';
import 'package:edtech_app/models/chat_message.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/hover_scale.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Channel> _channels = [];
  Channel? _selected;
  List<ChatMessage> _messages = [];
  bool _loading = false;
  String? _error;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() => _loading = true);
    try {
      _channels = await ApiService.instance.getChannels('c-001');
      if (_channels.isNotEmpty) {
        await _selectChannel(_channels.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _selectChannel(Channel channel) async {
    setState(() {
      _selected = channel;
      _messages = [];
      _loading = true;
      _error = null;
    });
    try {
      _messages = await ApiService.instance.getMessages(channel.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final body = _controller.text.trim();
    final userId = context.read<AuthProvider>().user?.id;
    if (body.isEmpty || _selected == null || userId == null) return;
    _controller.clear();
    try {
      await ApiService.instance.postMessage(
        channelId: _selected!.id,
        authorId: userId,
        body: body,
      );
      await _selectChannel(_selected!);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $error'),
            backgroundColor: kError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_loading && _selected == null)
          const LinearProgressIndicator(minHeight: 4)
        else if (_error != null && _selected == null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: kError, size: 48),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _loadChannels,
                  style: FilledButton.styleFrom(
                    foregroundColor: kPrimary,
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                Container(
                  color: kSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _channels.length,
                      itemBuilder: (context, index) {
                        final channel = _channels[index];
                        final isSelected = _selected?.id == channel.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: HoverScale(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? kPrimary : kCard,
                                border: Border.all(
                                  color: isSelected ? kPrimary : kBorder,
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _selectChannel(channel),
                                  borderRadius: BorderRadius.circular(22),
                                  child: Center(
                                    child: Text(
                                      channel.name,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : kTextSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(color: kTextSecondary),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message =
                                _messages[_messages.length - 1 - index];
                            final userId =
                                context.watch<AuthProvider>().user?.id;
                            return MessageBubble(
                              message: message,
                              isOwn: message.authorId == userId,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kSurface,
            border: Border(top: BorderSide(color: kBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Send message (Enter)',
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              HoverScale(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: livelyGradient(kPrimary, kPrimaryDark),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
