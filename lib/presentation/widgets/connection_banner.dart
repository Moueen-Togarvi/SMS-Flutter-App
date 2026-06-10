import 'package:flutter/material.dart';

import '../../domain/entities/connection_status.dart';
import '../providers/bluetooth_provider.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.state});

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    final current = state;
    if (current == null || current.status == BluetoothConnectionStatus.idle) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final (icon, text, color) = switch (current.status) {
      BluetoothConnectionStatus.connected => (
          Icons.bluetooth_connected_rounded,
          'Connected to ${current.connectedDevice?.name ?? 'nearby device'}',
          scheme.primary,
        ),
      BluetoothConnectionStatus.connecting => (
          Icons.sync_rounded,
          'Connecting to ${current.connectedDevice?.name ?? 'device'}',
          scheme.tertiary,
        ),
      BluetoothConnectionStatus.reconnecting => (
          Icons.sync_problem_rounded,
          'Connection lost. Trying to reconnect.',
          scheme.tertiary,
        ),
      BluetoothConnectionStatus.bluetoothOff => (
          Icons.bluetooth_disabled_rounded,
          'Bluetooth is disabled or unavailable.',
          scheme.error,
        ),
      BluetoothConnectionStatus.error => (
          Icons.error_outline_rounded,
          current.errorMessage ?? 'Bluetooth error.',
          scheme.error,
        ),
      _ => (
          Icons.bluetooth_searching_rounded,
          'Searching for devices.',
          scheme.primary,
        ),
    };

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: scheme.onSurface))),
        ],
      ),
    );
  }
}

