enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

class MessageEntity {
  const MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.status,
    required this.isLocalSender,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isLocalSender;

  MessageEntity copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isLocalSender,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isLocalSender: isLocalSender ?? this.isLocalSender,
    );
  }
}

