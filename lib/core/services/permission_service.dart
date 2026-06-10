import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<PermissionResult> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) {
      return const PermissionResult(granted: false, permanentlyDenied: false);
    }

    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ];

    final statuses = await permissions.request();
    final denied = statuses.values.where((status) => !status.isGranted).toList();
    return PermissionResult(
      granted: denied.isEmpty,
      permanentlyDenied: denied.any((status) => status.isPermanentlyDenied),
    );
  }

  Future<bool> hasBluetoothPermissions() async {
    if (!Platform.isAndroid) return false;
    final scan = await Permission.bluetoothScan.status;
    final connect = await Permission.bluetoothConnect.status;
    final location = await Permission.locationWhenInUse.status;
    return scan.isGranted && connect.isGranted && location.isGranted;
  }

  Future<void> openSystemSettings() => openAppSettings();
}

class PermissionResult {
  const PermissionResult({
    required this.granted,
    required this.permanentlyDenied,
  });

  final bool granted;
  final bool permanentlyDenied;
}

