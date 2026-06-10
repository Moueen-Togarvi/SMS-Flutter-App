import 'package:isar_community/isar.dart';

import '../../domain/entities/message_entity.dart';

part 'message_model.g.dart';

@collection
class MessageModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String messageId;

  @Index()
  late String chatId;

  @Index()
  late String senderId;

  late String receiverId;
  late String text;
  late DateTime timestamp;
  late bool isLocalSender;

  @Enumerated(EnumType.name)
  late MessageStatus status;

  MessageEntity toEntity() {
    return MessageEntity(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: timestamp,
      status: status,
      isLocalSender: isLocalSender,
    );
  }

  static MessageModel fromEntity(MessageEntity entity) {
    return MessageModel()
      ..messageId = entity.id
      ..chatId = entity.chatId
      ..senderId = entity.senderId
      ..receiverId = entity.receiverId
      ..text = entity.text
      ..timestamp = entity.timestamp.toUtc()
      ..status = entity.status
      ..isLocalSender = entity.isLocalSender;
  }
}

