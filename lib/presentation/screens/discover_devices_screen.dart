import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bluetooth_device_entity.dart';
import '../../domain/entities/connection_status.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/device_tile.dart';

class DiscoverDevicesScreen extends ConsumerWidget {
  const DiscoverDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluetoothAsync = ref.watch(bluetoothProvider);
    final bluetooth = bluetoothAsync.valueOrNull ?? const BluetoothState();
    final scanning = bluetooth.status == BluetoothConnectionStatus.discovering;

    ref.listen(bluetoothProvider, (previous, next) {
      final error = next.valueOrNull?.errorMessage;
      if (error != null && error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover devices'),
        actions: [
          IconButton(
            tooltip: 'Make discoverable',
            onPressed: () => ref.read(bluetoothProvider.notifier).makeDiscoverable(),
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(bluetoothProvider.notifier).startDiscovery(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _StatusPanel(state: bluetooth),
            const SizedBox(height: 16),
            Text('Nearby and paired devices', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (bluetooth.devices.isEmpty)
              const _EmptyDevices()
            else
              ...bluetooth.devices.map((device) => DeviceTile(
                    device: device,
                    connecting: bluetooth.status == BluetoothConnectionStatus.connecting &&
                        bluetooth.connectedDevice?.address == device.address,
                    onConnect: () => _connect(context, ref, device),
                  )),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: scanning ? null : () => ref.read(bluetoothProvider.notifier).startDiscovery(),
          icon: scanning
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded),
          label: Text(scanning ? 'Scanning...' : 'Scan again'),
        ),
      ),
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref, BluetoothDeviceEntity device) async {
    try {
      await ref.read(bluetoothProvider.notifier).connect(device);
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to connect: $error')));
    }
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.state});

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.bluetooth_rounded, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                switch (state.status) {
                  BluetoothConnectionStatus.discovering => 'Scanning for nearby Bluetooth devices.',
                  BluetoothConnectionStatus.connected => 'Connected to ${state.connectedDevice?.name ?? 'a device'}.',
                  BluetoothConnectionStatus.connecting => 'Connecting...',
                  BluetoothConnectionStatus.reconnecting => 'Trying to reconnect...',
                  BluetoothConnectionStatus.bluetoothOff => 'Bluetooth appears to be disabled.',
                  _ => 'Pull to refresh or scan to find devices.',
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.bluetooth_disabled_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('No devices found yet'),
          const SizedBox(height: 4),
          Text(
            'Make the other phone discoverable, then scan again.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

