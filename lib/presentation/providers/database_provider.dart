import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/isar_database.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/user_repository.dart';

final databaseProvider = FutureProvider<IsarDatabase>((ref) async {
  final database = await IsarDatabase.open();
  ref.onDispose(() => database.isar.close());
  return database;
});

final userRepositoryProvider = FutureProvider<UserRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return UserRepository(database.isar);
});

final chatRepositoryProvider = FutureProvider<ChatRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return ChatRepository(database.isar);
});

final messageRepositoryProvider = FutureProvider<MessageRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return MessageRepository(database.isar);
});

