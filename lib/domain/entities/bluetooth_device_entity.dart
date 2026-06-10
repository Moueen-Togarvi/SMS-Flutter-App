class BluetoothDeviceEntity {
  const BluetoothDeviceEntity({
    required this.name,
    required this.address,
    required this.bonded,
  });

  final String name;
  final String address;
  final bool bonded;

  factory BluetoothDeviceEntity.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDeviceEntity(
      name: (map['name'] as String?)?.trim().isNotEmpty == true ? map['name'] as String : 'Unknown device',
      address: map['address'] as String? ?? '',
      bonded: map['bonded'] as bool? ?? false,
    );
  }
}

