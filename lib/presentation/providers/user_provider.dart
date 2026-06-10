import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';
import 'bluetooth_provider.dart';
import 'database_provider.dart';

final userProvider = AsyncNotifierProvider<UserController, UserProfile?>(UserController.new);

class UserController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final repository = await ref.watch(userRepositoryProvider.future);
    final profile = await repository.getLocalProfile();
    if (profile != null) {
      ref.read(bluetoothProvider.notifier).setLocalProfile(profile);
    }
    return profile;
  }

  Future<void> saveUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.length < 2) {
      throw ArgumentError('Username must be at least 2 characters.');
    }

    state = const AsyncLoading();
    final repository = await ref.read(userRepositoryProvider.future);
    final current = await repository.getLocalProfile();
    final profile = current == null
        ? await repository.createLocalProfile(trimmed)
        : current.copyWith(username: trimmed);

    if (current != null) {
      await repository.saveLocalProfile(profile);
    }

    ref.read(bluetoothProvider.notifier).setLocalProfile(profile);
    state = AsyncData(profile);
  }
}

