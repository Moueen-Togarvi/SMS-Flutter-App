import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_entity.dart';
import 'database_provider.dart';

final chatProvider = StreamProvider<List<ChatEntity>>((ref) async* {
  final repository = await ref.watch(chatRepositoryProvider.future);
  yield* repository.watchChats();
});

final chatByIdProvider = FutureProvider.family<ChatEntity?, String>((ref, chatId) async {
  final repository = await ref.watch(chatRepositoryProvider.future);
  return repository.findChat(chatId);
});

