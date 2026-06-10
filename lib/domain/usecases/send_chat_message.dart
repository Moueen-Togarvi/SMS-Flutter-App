import '../entities/chat_entity.dart';

typedef SendChatMessage = Future<void> Function(ChatEntity chat, String text);

