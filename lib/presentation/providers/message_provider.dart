import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message_entity.dart';
import 'database_provider.dart';

final messageProvider = StreamProvider.family<List<MessageEntity>, String>((ref, chatId) async* {
  final repository = await ref.watch(messageRepositoryProvider.future);
  yield* repository.watchMessages(chatId);
});

