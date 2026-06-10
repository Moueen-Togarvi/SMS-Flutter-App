import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../bluetooth/bluetooth_service.dart';
import '../../bluetooth/protocol.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/permission_service.dart';
import '../../domain/entities/bluetooth_device_entity.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/connection_status.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_profile.dart';
import 'database_provider.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) => PermissionService());
final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final service = BluetoothService();
  ref.onDispose(service.dispose);
  return service;
});

final bluetoothProvider = AsyncNotifierProvider<BluetoothController, BluetoothState>(BluetoothController.new);

class BluetoothController extends AsyncNotifier<BluetoothState> {
  StreamSubscription<BluetoothConnectionStatus>? _connectionSub;
  StreamSubscription<BluetoothDeviceEntity>? _deviceSub;
  StreamSubscription<BluetoothPacket>? _packetSub;
  StreamSubscription<BluetoothError>? _errorSub;
  UserProfile? _localProfile;
  String? _lastAddress;

  @override
  Future<BluetoothState> build() async {
    final service = ref.watch(bluetoothServiceProvider);
    await service.initialize(profile: _localProfile);

    _connectionSub = service.connectionState.listen(_onConnectionStatus);
    _deviceSub = service.discoveredDevices.listen(_onDevice);
    _packetSub = service.incomingPackets.listen(_onPacket);
    _errorSub = service.bluetoothErrors.listen(_onError);

    ref.onDispose(() {
      _connectionSub?.cancel();
      _deviceSub?.cancel();
      _packetSub?.cancel();
      _errorSub?.cancel();
    });

    final enabled = await service.isEnabled();
    return BluetoothState(
      status: enabled ? BluetoothConnectionStatus.idle : BluetoothConnectionStatus.bluetoothOff,
    );
  }

  void setLocalProfile(UserProfile profile) {
    _localProfile = profile;
    ref.read(bluetoothServiceProvider).updateLocalProfile(profile);
  }

  Future<bool> requestPermissions() async {
    final result = await ref.read(permissionServiceProvider).requestBluetoothPermissions();
    if (!result.granted) {
      _setState((current) => current.copyWith(errorMessage: 'Bluetooth permissions are required.'));
      return false;
    }
    return true;
  }

  Future<void> startDiscovery() async {
    final granted = await requestPermissions();
    if (!granted) return;
    final service = ref.read(bluetoothServiceProvider);
    final paired = await service.pairedDevices();
    _setState((current) => current.copyWith(
          status: BluetoothConnectionStatus.discovering,
          devices: _mergeDevices(current.devices, paired),
          errorMessage: null,
        ));
    await service.startDiscovery();
  }

  Future<void> stopDiscovery() => ref.read(bluetoothServiceProvider).stopDiscovery();

  Future<void> makeDiscoverable() => ref.read(bluetoothServiceProvider).makeDiscoverable();

  Future<void> connect(BluetoothDeviceEntity device) async {
    _lastAddress = device.address;
    _setState((current) => current.copyWith(
          status: BluetoothConnectionStatus.connecting,
          connectedDevice: device,
          errorMessage: null,
        ));
    await ref.read(bluetoothServiceProvider).connect(device.address);
  }

  Future<void> disconnect() async {
    _lastAddress = null;
    await ref.read(bluetoothServiceProvider).disconnect();
  }

  Future<void> sendChatMessage(ChatEntity chat, String text) async {
    final profile = _localProfile;
    if (profile == null) throw StateError('Local profile is not ready.');

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final message = MessageEntity(
      id: const Uuid().v4(),
      chatId: chat.id,
      senderId: profile.deviceId,
      receiverId: chat.peerDeviceId,
      text: trimmed,
      timestamp: DateTime.now().toUtc(),
      status: MessageStatus.sending,
      isLocalSender: true,
    );

    final messageRepository = await ref.read(messageRepositoryProvider.future);
    final chatRepository = await ref.read(chatRepositoryProvider.future);
    await messageRepository.save(message);
    await chatRepository.updateFromMessage(message, peerName: chat.peerName, peerAddress: chat.peerAddress);

    await ref.read(bluetoothServiceProvider).sendMessage(message);
    await messageRepository.updateStatus(message.id, MessageStatus.sent);
  }

  Future<void> markChatRead(ChatEntity chat) async {
    final messageRepository = await ref.read(messageRepositoryProvider.future);
    final chatRepository = await ref.read(chatRepositoryProvider.future);
    final ids = await messageRepository.markIncomingRead(chat.id);
    await chatRepository.markRead(chat.id);
    for (final id in ids) {
      unawaited(ref.read(bluetoothServiceProvider).sendReadReceipt(id));
    }
  }

  void _onConnectionStatus(BluetoothConnectionStatus status) {
    _setState((current) => current.copyWith(status: status));
    if (status == BluetoothConnectionStatus.disconnected && _lastAddress != null) {
      unawaited(_reconnect());
    }
  }

  void _onDevice(BluetoothDeviceEntity device) {
    _setState((current) => current.copyWith(devices: _mergeDevices(current.devices, [device])));
  }

  Future<void> _onPacket(BluetoothPacket packet) async {
    switch (packet) {
      case HandshakePacket():
        final userRepository = await ref.read(userRepositoryProvider.future);
        final chatRepository = await ref.read(chatRepositoryProvider.future);
        final profile = UserProfile(deviceId: packet.deviceId, username: packet.username);
        await userRepository.savePeerProfile(profile);
        await chatRepository.upsertPeerChat(peerDeviceId: packet.deviceId, peerName: packet.username);
      case MessagePacket():
        final local = _localProfile;
        final userRepository = await ref.read(userRepositoryProvider.future);
        final chatRepository = await ref.read(chatRepositoryProvider.future);
        final messageRepository = await ref.read(messageRepositoryProvider.future);
        final peer = await userRepository.findByDeviceId(packet.senderId);
        final chatId = packet.senderId == local?.deviceId ? packet.receiverId : packet.senderId;
        final message = MessageEntity(
          id: packet.id,
          chatId: chatId,
          senderId: packet.senderId,
          receiverId: packet.receiverId,
          text: packet.text,
          timestamp: packet.timestamp.toUtc(),
          status: MessageStatus.delivered,
          isLocalSender: packet.senderId == local?.deviceId,
        );
        await messageRepository.save(message);
        await chatRepository.updateFromMessage(
          message,
          peerName: peer?.username ?? 'Nearby device',
        );
        if (!message.isLocalSender) {
          unawaited(ref.read(bluetoothServiceProvider).sendDeliveryReceipt(message.id));
        }
      case ReceiptPacket():
        final repository = await ref.read(messageRepositoryProvider.future);
        final status = packet.type == 'read' ? MessageStatus.read : MessageStatus.delivered;
        await repository.updateStatus(packet.messageId, status);
    }
  }

  void _onError(BluetoothError error) {
    _setState((current) => current.copyWith(
          status: BluetoothConnectionStatus.error,
          errorMessage: error.message,
        ));
  }

  Future<void> _reconnect() async {
    final address = _lastAddress;
    if (address == null) return;
    for (var attempt = 0; attempt < AppConstants.reconnectAttempts; attempt++) {
      await Future<void>.delayed(AppConstants.reconnectDelay);
      final current = state.valueOrNull;
      if (current?.status == BluetoothConnectionStatus.connected) return;
      _setState((value) => value.copyWith(status: BluetoothConnectionStatus.reconnecting));
      try {
        await ref.read(bluetoothServiceProvider).connect(address);
        return;
      } catch (_) {
        // Try again until attempts are exhausted.
      }
    }
  }

  void _setState(BluetoothState Function(BluetoothState current) update) {
    final current = state.valueOrNull ?? const BluetoothState();
    state = AsyncData(update(current));
  }

  List<BluetoothDeviceEntity> _mergeDevices(
    List<BluetoothDeviceEntity> current,
    List<BluetoothDeviceEntity> incoming,
  ) {
    final byAddress = {
      for (final device in current) device.address: device,
      for (final device in incoming) device.address: device,
    };
    final devices = byAddress.values.toList()
      ..sort((a, b) {
        if (a.bonded != b.bonded) return a.bonded ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return devices;
  }
}

class BluetoothState {
  const BluetoothState({
    this.status = BluetoothConnectionStatus.idle,
    this.devices = const [],
    this.connectedDevice,
    this.errorMessage,
  });

  final BluetoothConnectionStatus status;
  final List<BluetoothDeviceEntity> devices;
  final BluetoothDeviceEntity? connectedDevice;
  final String? errorMessage;

  bool get isConnected => status == BluetoothConnectionStatus.connected;

  BluetoothState copyWith({
    BluetoothConnectionStatus? status,
    List<BluetoothDeviceEntity>? devices,
    BluetoothDeviceEntity? connectedDevice,
    String? errorMessage,
  }) {
    return BluetoothState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      errorMessage: errorMessage,
    );
  }
}
