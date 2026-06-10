import 'package:bluechat/bluetooth/protocol.dart';
import 'package:bluechat/domain/entities/message_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes and deserializes message packets', () {
    final message = MessageEntity(
      id: 'm1',
      chatId: 'peer',
      senderId: 'local',
      receiverId: 'peer',
      text: 'Hello',
      timestamp: DateTime.utc(2026, 1, 1, 10),
      status: MessageStatus.sending,
      isLocalSender: true,
    );

    final encoded = ProtocolCodec.encode(MessagePacket.fromEntity(message));
    final decoded = ProtocolCodec.decode(encoded);

    expect(decoded, isA<MessagePacket>());
    final packet = decoded as MessagePacket;
    expect(packet.id, 'm1');
    expect(packet.text, 'Hello');
    expect(packet.timestamp, DateTime.utc(2026, 1, 1, 10));
  });

  test('serializes receipt packets', () {
    final delivered = ProtocolCodec.decode(ProtocolCodec.encode(const ReceiptPacket.delivered('m1')));
    final read = ProtocolCodec.decode(ProtocolCodec.encode(const ReceiptPacket.read('m2')));

    expect(delivered, isA<ReceiptPacket>());
    expect((delivered as ReceiptPacket).type, 'delivered');
    expect(read, isA<ReceiptPacket>());
    expect((read as ReceiptPacket).type, 'read');
  });

  test('rejects invalid packets', () {
    expect(() => ProtocolCodec.decode('[]'), throwsFormatException);
    expect(() => ProtocolCodec.decode('{"type":"unknown"}'), throwsFormatException);
  });
}

