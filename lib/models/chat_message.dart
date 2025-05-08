class ChatMessage {
  final String id;
  final String userId;
  final String content;
  final bool isUser;
  final String? imageUrl;
  final String chatId;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.content,
    required this.isUser,
    this.imageUrl,
    required this.chatId,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      isUser: json['is_user'] ?? true,
      imageUrl: json['image_url'],
      chatId: json['chat_id'] ?? 'default',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'is_user': isUser,
      'image_url': imageUrl,
      'chat_id': chatId,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 