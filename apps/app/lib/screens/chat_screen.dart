import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/models/channel.dart';
import 'package:edtech_app/models/chat_message.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bounce_tap.dart';
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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    setState(() => _loading = true);
    try {
      _channels = await ApiService.instance.getChannels('c-001');
      if (_channels.isNotEmpty) {
        await _selectChannel(_channels.first);
      } else {
        if (mounted) setState(() => _loading = false);
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
      _scrollToBottom();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(kSpaceMd),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().user?.role == 'admin';

    return Column(
      children: [
        if (_loading && _selected == null)
          const LinearProgressIndicator(minHeight: 3, color: kPrimary)
        else if (_error != null && _selected == null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😵', style: TextStyle(fontSize: 52)),
                const SizedBox(height: kSpaceMd),
                Text(
                  _error!,
                  style: context.body2.copyWith(color: kTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: kSpaceLg),
                FilledButton.tonalIcon(
                  onPressed: _loadChannels,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                  style: FilledButton.styleFrom(foregroundColor: kPrimary),
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
                  padding: const EdgeInsets.symmetric(horizontal: kSpaceMd, vertical: kSpaceSm),
                  child: SizedBox(
                    height: 46,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _channels.length,
                      itemBuilder: (context, index) {
                        final channel = _channels[index];
                        final isSelected = _selected?.id == channel.id;
                        final color = kAccent;
                        return Padding(
                          padding: const EdgeInsets.only(right: kSpaceSm),
                          child: GestureDetector(
                            onTap: () => _selectChannel(channel),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: kSpaceMd,
                                vertical: kSpaceSm,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? color : kCard,
                                border: Border.all(
                                  color: isSelected ? color : kDivider,
                                ),
                                borderRadius: BorderRadius.circular(kRadiusMd),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  channel.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : kTextSecondary,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13,
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
                if (isAdmin && _selected != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: kSpaceMd),
                    child: Text(
                      '#${_selected!.name} • Admin can edit messages',
                      style: context.caption.copyWith(
                        color: kTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('💬', style: TextStyle(fontSize: 56)),
                              const SizedBox(height: kSpaceMd),
                              Text(
                                'No messages yet',
                                style: context.h4.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: kTextPrimary,
                                ),
                              ),
                              const SizedBox(height: kSpaceSm),
                              Text(
                                'Say hello! 👋',
                                style: context.body2.copyWith(color: kTextSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: kSpaceMd),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[_messages.length - 1 - index];
                            final userId = context.watch<AuthProvider>().user?.id;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: kSpaceMd),
                              child: MessageBubble(
                                message: message,
                                isOwn: message.authorId == userId,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(kSpaceMd),
          decoration: const BoxDecoration(
            color: kSurface,
            border: Border(top: BorderSide(color: kDivider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Write a message...',
                    filled: true,
                    fillColor: kBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: kSpaceMd, vertical: kSpaceMd),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusMd),
                      borderSide: BorderSide(color: kDivider, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusMd),
                      borderSide: BorderSide(color: kDivider, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusMd),
                      borderSide: BorderSide(color: kPrimary, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: kSpaceSm),
              BounceTap(
                onTap: _sendMessage,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: livelyGradient(kPrimary, kPrimaryDark),
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(kSpaceMd),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
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
