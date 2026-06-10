import 'dart:convert';

import '../core/constants/app_constants.dart';
import '../domain/entities/message_entity.dart';
import '../domain/entities/user_profile.dart';

sealed class BluetoothPacket {
  const BluetoothPacket(this.type);

  final String type;

  Map<String, dynamic> toJson();
}

class HandshakePacket extends BluetoothPacket {
  const HandshakePacket({
    required this.deviceId,
    required this.username,
    this.protocolVersion = AppConstants.protocolVersion,
  }) : super('handshake');

  final String deviceId;
  final String username;
  final int protocolVersion;

  factory HandshakePacket.fromProfile(UserProfile profile) {
    return HandshakePacket(deviceId: profile.deviceId, username: profile.username);
  }

  factory HandshakePacket.fromJson(Map<String, dynamic> json) {
    return HandshakePacket(
      deviceId: json['deviceId'] as String,
      username: json['username'] as String,
      protocolVersion: json['protocolVersion'] as int? ?? 1,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'deviceId': deviceId,
        'username': username,
        'protocolVersion': protocolVersion,
      };
}

class MessagePacket extends BluetoothPacket {
  const MessagePacket({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  }) : super('message');

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;

  factory MessagePacket.fromEntity(MessageEntity message) {
    return MessagePacket(
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId,
      text: message.text,
      timestamp: message.timestamp.toUtc(),
    );
  }

  factory MessagePacket.fromJson(Map<String, dynamic> json) {
    return MessagePacket(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'timestamp': timestamp.toUtc().toIso8601String(),
      };
}

class ReceiptPacket extends BluetoothPacket {
  const ReceiptPacket.delivered(this.messageId) : super('delivered');
  const ReceiptPacket.read(this.messageId) : super('read');

  final String messageId;

  factory ReceiptPacket.fromJson(String type, Map<String, dynamic> json) {
    return switch (type) {
      'delivered' => ReceiptPacket.delivered(json['messageId'] as String),
      'read' => ReceiptPacket.read(json['messageId'] as String),
      _ => throw const FormatException('Unsupported receipt packet.'),
    };
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'messageId': messageId,
      };
}

class ProtocolCodec {
  const ProtocolCodec._();

  static String encode(BluetoothPacket packet) => '${jsonEncode(packet.toJson())}\n';

  static BluetoothPacket decode(String line) {
    final decoded = jsonDecode(line.trim());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Packet must be a JSON object.');
    }
    final type = decoded['type'];
    return switch (type) {
      'handshake' => HandshakePacket.fromJson(decoded),
      'message' => MessagePacket.fromJson(decoded),
      'delivered' || 'read' => ReceiptPacket.fromJson(type as String, decoded),
      _ => throw FormatException('Unsupported packet type: $type'),
    };
  }
}

