import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/entities/bluetooth_device_entity.dart';
import '../domain/entities/connection_status.dart';
import '../domain/entities/message_entity.dart';
import '../domain/entities/user_profile.dart';
import 'protocol.dart';

class BluetoothService {
  BluetoothService({
    MethodChannel? methodChannel,
    EventChannel? connectionChannel,
    EventChannel? deviceChannel,
    EventChannel? messageChannel,
    EventChannel? errorChannel,
  })  : _methods = methodChannel ?? const MethodChannel('bluechat/bluetooth_methods'),
        _connectionChannel = connectionChannel ?? const EventChannel('bluechat/bluetooth_connection'),
        _deviceChannel = deviceChannel ?? const EventChannel('bluechat/bluetooth_devices'),
        _messageChannel = messageChannel ?? const EventChannel('bluechat/bluetooth_messages'),
        _errorChannel = errorChannel ?? const EventChannel('bluechat/bluetooth_errors');

  final MethodChannel _methods;
  final EventChannel _connectionChannel;
  final EventChannel _deviceChannel;
  final EventChannel _messageChannel;
  final EventChannel _errorChannel;

  final _packetController = StreamController<BluetoothPacket>.broadcast();
  final _messageController = StreamController<MessageEntity>.broadcast();
  final _connectionController = StreamController<BluetoothConnectionStatus>.broadcast();
  final _deviceController = StreamController<BluetoothDeviceEntity>.broadcast();
  final _errorController = StreamController<BluetoothError>.broadcast();

  StreamSubscription<dynamic>? _connectionSub;
  StreamSubscription<dynamic>? _deviceSub;
  StreamSubscription<dynamic>? _messageSub;
  StreamSubscription<dynamic>? _errorSub;
  UserProfile? _localProfile;

  Stream<MessageEntity> get incomingMessages => _messageController.stream;
  Stream<BluetoothPacket> get incomingPackets => _packetController.stream;
  Stream<BluetoothConnectionStatus> get connectionState => _connectionController.stream;
  Stream<BluetoothDeviceEntity> get discoveredDevices => _deviceController.stream;
  Stream<BluetoothError> get bluetoothErrors => _errorController.stream;

  Future<void> initialize({UserProfile? profile}) async {
    _localProfile = profile ?? _localProfile;
    await _methods.invokeMethod<bool>('initialize');
    _listenOnce();
  }

  void updateLocalProfile(UserProfile profile) {
    _localProfile = profile;
  }

  Future<bool> isEnabled() async {
    return await _methods.invokeMethod<bool>('isEnabled') ?? false;
  }

  Future<void> startDiscovery() async {
    _connectionController.add(BluetoothConnectionStatus.discovering);
    await _methods.invokeMethod<void>('startDiscovery');
  }

  Future<void> stopDiscovery() => _methods.invokeMethod<void>('stopDiscovery');

  Future<List<BluetoothDeviceEntity>> pairedDevices() async {
    final raw = await _methods.invokeListMethod<dynamic>('pairedDevices') ?? const [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(BluetoothDeviceEntity.fromMap)
        .where((device) => device.address.isNotEmpty)
        .toList();
  }

  Future<void> connect(String address) async {
    await _methods.invokeMethod<void>('connect', {'address': address});
  }

  Future<void> disconnect() => _methods.invokeMethod<void>('disconnect');

  Future<void> makeDiscoverable() => _methods.invokeMethod<void>('makeDiscoverable');

  Future<void> sendMessage(MessageEntity message) async {
    final packet = MessagePacket.fromEntity(message);
    await sendPacket(packet);
  }

  Future<void> sendDeliveryReceipt(String messageId) => sendPacket(ReceiptPacket.delivered(messageId));

  Future<void> sendReadReceipt(String messageId) => sendPacket(ReceiptPacket.read(messageId));

  Future<void> sendPacket(BluetoothPacket packet) async {
    await _methods.invokeMethod<void>('sendRaw', {'packet': ProtocolCodec.encode(packet)});
  }

  Future<void> _sendHandshakeIfReady() async {
    final profile = _localProfile;
    if (profile != null) {
      unawaited(sendPacket(HandshakePacket.fromProfile(profile)));
    }
  }

  void _listenOnce() {
    _connectionSub ??= _connectionChannel.receiveBroadcastStream().listen((event) {
      if (event is String) {
        final status = bluetoothConnectionStatusFromNative(event);
        _connectionController.add(status);
        if (status == BluetoothConnectionStatus.connected) {
          _sendHandshakeIfReady();
        }
      }
    }, onError: _addPlatformError);

    _deviceSub ??= _deviceChannel.receiveBroadcastStream().listen((event) {
      if (event is Map<dynamic, dynamic>) {
        final device = BluetoothDeviceEntity.fromMap(event);
        if (device.address.isNotEmpty) _deviceController.add(device);
      }
    }, onError: _addPlatformError);

    _messageSub ??= _messageChannel.receiveBroadcastStream().listen((event) {
      if (event is String) {
        try {
          final packet = ProtocolCodec.decode(event);
          _packetController.add(packet);
          if (packet is MessagePacket) {
            final localId = _localProfile?.deviceId ?? packet.receiverId;
            _messageController.add(
              MessageEntity(
                id: packet.id,
                chatId: packet.senderId,
                senderId: packet.senderId,
                receiverId: packet.receiverId,
                text: packet.text,
                timestamp: packet.timestamp,
                status: MessageStatus.delivered,
                isLocalSender: packet.senderId == localId,
              ),
            );
          }
        } on FormatException catch (error) {
          _errorController.add(BluetoothError(code: 'INVALID_PACKET', message: error.message));
        }
      }
    }, onError: _addPlatformError);

    _errorSub ??= _errorChannel.receiveBroadcastStream().listen((event) {
      if (event is Map<dynamic, dynamic>) {
        _errorController.add(
          BluetoothError(
            code: event['code'] as String? ?? 'BLUETOOTH_ERROR',
            message: event['message'] as String? ?? 'Bluetooth error.',
          ),
        );
      }
    }, onError: _addPlatformError);
  }

  void _addPlatformError(Object error) {
    _errorController.add(BluetoothError(code: 'PLATFORM_ERROR', message: error.toString()));
  }

  Future<void> dispose() async {
    await _connectionSub?.cancel();
    await _deviceSub?.cancel();
    await _messageSub?.cancel();
    await _errorSub?.cancel();
    await _packetController.close();
    await _messageController.close();
    await _connectionController.close();
    await _deviceController.close();
    await _errorController.close();
  }
}

class BluetoothError {
  const BluetoothError({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}
