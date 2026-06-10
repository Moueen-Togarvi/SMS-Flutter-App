import 'package:isar_community/isar.dart';

import '../../domain/entities/chat_entity.dart';

part 'chat_model.g.dart';

@collection
class ChatModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String chatId;

  @Index()
  late String peerDeviceId;

  late String peerName;
  late String peerAddress;
  late String lastMessage;
  late DateTime lastActivity;
  late int unreadCount;

  ChatEntity toEntity() {
    return ChatEntity(
      id: chatId,
      peerDeviceId: peerDeviceId,
      peerName: peerName,
      peerAddress: peerAddress,
      lastMessage: lastMessage,
      lastActivity: lastActivity,
      unreadCount: unreadCount,
    );
  }
}

