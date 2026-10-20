class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.authorId,
    required this.body,
    required this.sentAt,
  });

  final String id;
  final String channelId;
  final String authorId;
  final String body;
  final DateTime sentAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      channelId: json['channelId'] as String,
      authorId: json['authorId'] as String,
      body: json['body'] as String,
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'channelId': channelId,
      'authorId': authorId,
      'body': body,
      'sentAt': sentAt.toIso8601String(),
    };
  }
}
