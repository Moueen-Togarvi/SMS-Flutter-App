import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProvider).valueOrNull;
    final settings = ref.watch(settingsProvider);
    _controller.text = profile?.username ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => ref.read(userProvider.notifier).saveUsername(_controller.text),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save username'),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Device ID'),
            subtitle: Text(profile?.deviceId ?? 'Not created yet'),
          ),
          const Divider(),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.phone_android_rounded)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (value) => ref.read(settingsProvider.notifier).setThemeMode(value.first),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.read(bluetoothProvider.notifier).disconnect(),
            icon: const Icon(Icons.link_off_rounded),
            label: const Text('Disconnect Bluetooth'),
          ),
        ],
      ),
    );
  }
}

