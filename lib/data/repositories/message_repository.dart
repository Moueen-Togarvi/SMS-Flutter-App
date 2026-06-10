import 'package:isar_community/isar.dart';

import '../../domain/entities/message_entity.dart';
import '../models/message_model.dart';

class MessageRepository {
  MessageRepository(this._isar);

  final Isar _isar;

  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return _isar.messageModels
        .filter()
        .chatIdEqualTo(chatId)
        .watch(fireImmediately: true)
        .map(_sortMessages);
  }

  Future<void> save(MessageEntity message) async {
    final existing = await _isar.messageModels.filter().messageIdEqualTo(message.id).findFirst();
    final model = MessageModel.fromEntity(message);
    if (existing != null) model.id = existing.id;
    await _isar.writeTxn(() => _isar.messageModels.put(model));
  }

  Future<void> updateStatus(String messageId, MessageStatus status) async {
    final message = await _isar.messageModels.filter().messageIdEqualTo(messageId).findFirst();
    if (message == null) return;
    message.status = _maxStatus(message.status, status);
    await _isar.writeTxn(() => _isar.messageModels.put(message));
  }

  Future<List<String>> markIncomingRead(String chatId) async {
    final candidates = await _isar.messageModels
        .filter()
        .chatIdEqualTo(chatId)
        .isLocalSenderEqualTo(false)
        .findAll();
    final unread = candidates.where((message) => message.status != MessageStatus.read).toList();

    final ids = unread.map((message) => message.messageId).toList();
    if (unread.isEmpty) return ids;
    for (final message in unread) {
      message.status = MessageStatus.read;
    }
    await _isar.writeTxn(() => _isar.messageModels.putAll(unread));
    return ids;
  }

  MessageStatus _maxStatus(MessageStatus current, MessageStatus next) {
    return next.index > current.index ? next : current;
  }

  List<MessageEntity> _sortMessages(List<MessageModel> models) {
    final sorted = [...models]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted.map((model) => model.toEntity()).toList();
  }
}
