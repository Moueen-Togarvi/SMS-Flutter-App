enum BluetoothConnectionStatus {
  idle,
  bluetoothOff,
  discovering,
  discoveryFinished,
  connecting,
  connected,
  disconnected,
  reconnecting,
  error,
}

BluetoothConnectionStatus bluetoothConnectionStatusFromNative(String value) {
  return switch (value) {
    'discovering' => BluetoothConnectionStatus.discovering,
    'discoveryFinished' => BluetoothConnectionStatus.discoveryFinished,
    'connecting' => BluetoothConnectionStatus.connecting,
    'connected' => BluetoothConnectionStatus.connected,
    'disconnected' => BluetoothConnectionStatus.disconnected,
    'reconnecting' => BluetoothConnectionStatus.reconnecting,
    'bluetoothOff' => BluetoothConnectionStatus.bluetoothOff,
    'error' => BluetoothConnectionStatus.error,
    _ => BluetoothConnectionStatus.idle,
  };
}

