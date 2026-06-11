import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_entity.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_list_tile.dart';
import '../widgets/connection_banner.dart';
import 'chat_screen.dart';
import 'discover_devices_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatProvider);
    final bluetooth = ref.watch(bluetoothProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BlueChat'),
        actions: [
          IconButton(
            tooltip: 'Discover devices',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DiscoverDevicesScreen())),
            icon: const Icon(Icons.bluetooth_searching_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          ConnectionBanner(state: bluetooth),
          Expanded(
            child: chats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Unable to load chats: $error')),
              data: (items) => items.isEmpty ? const _EmptyChats() : _ChatList(chats: items),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DiscoverDevicesScreen())),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Connect'),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({required this.chats});

  final List<ChatEntity> chats;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: chats.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListTile(
          chat: chat,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(chat: chat))),
        );
      },
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('No chats yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Discover a nearby Android device to start an offline conversation.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
