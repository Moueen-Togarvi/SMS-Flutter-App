import 'package:isar_community/isar.dart';

import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../models/chat_model.dart';

class ChatRepository {
  ChatRepository(this._isar);

  final Isar _isar;

  Stream<List<ChatEntity>> watchChats() {
    return _isar.chatModels.where().watch(fireImmediately: true).map(_sortChats);
  }

  Future<List<ChatEntity>> allChats() async {
    return _sortChats(await _isar.chatModels.where().findAll());
  }

  Future<ChatEntity?> findChat(String chatId) async {
    return (await _isar.chatModels.filter().chatIdEqualTo(chatId).findFirst())?.toEntity();
  }

  Future<ChatEntity> upsertPeerChat({
    required String peerDeviceId,
    required String peerName,
    String peerAddress = '',
  }) async {
    final existing = await _isar.chatModels.filter().chatIdEqualTo(peerDeviceId).findFirst();
    final model = existing ??
        (ChatModel()
          ..chatId = peerDeviceId
          ..peerDeviceId = peerDeviceId
          ..lastMessage = ''
          ..lastActivity = DateTime.now().toUtc()
          ..unreadCount = 0);

    model
      ..peerName = peerName
      ..peerAddress = peerAddress;

    await _isar.writeTxn(() => _isar.chatModels.put(model));
    return model.toEntity();
  }

  Future<void> updateFromMessage(MessageEntity message, {required String peerName, String peerAddress = ''}) async {
    final peerId = message.isLocalSender ? message.receiverId : message.senderId;
    final existing = await _isar.chatModels.filter().chatIdEqualTo(message.chatId).findFirst();
    final model = existing ??
        (ChatModel()
          ..chatId = message.chatId
          ..peerDeviceId = peerId
          ..peerName = peerName
          ..peerAddress = peerAddress
          ..unreadCount = 0);

    model
      ..lastMessage = message.text
      ..lastActivity = message.timestamp.toUtc();

    if (!message.isLocalSender) {
      model.unreadCount = model.unreadCount + 1;
    }

    await _isar.writeTxn(() => _isar.chatModels.put(model));
  }

  Future<void> markRead(String chatId) async {
    final chat = await _isar.chatModels.filter().chatIdEqualTo(chatId).findFirst();
    if (chat == null) return;
    chat.unreadCount = 0;
    await _isar.writeTxn(() => _isar.chatModels.put(chat));
  }

  List<ChatEntity> _sortChats(List<ChatModel> models) {
    final sorted = [...models]..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return sorted.map((model) => model.toEntity()).toList();
  }
}
