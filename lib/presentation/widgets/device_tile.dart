import 'package:flutter/material.dart';

import '../../domain/entities/bluetooth_device_entity.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.device,
    required this.connecting,
    required this.onConnect,
  });

  final BluetoothDeviceEntity device;
  final bool connecting;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(device.bonded ? Icons.devices_rounded : Icons.bluetooth_rounded),
        title: Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${device.address}${device.bonded ? ' · paired' : ''}'),
        trailing: FilledButton(
          onPressed: connecting ? null : onConnect,
          child: connecting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Connect'),
        ),
      ),
    );
  }
}

