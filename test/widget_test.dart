import 'package:bluechat/domain/entities/message_entity.dart';
import 'package:bluechat/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('message bubble aligns local messages to the right', (tester) async {
    final message = MessageEntity(
      id: 'm1',
      chatId: 'peer',
      senderId: 'local',
      receiverId: 'peer',
      text: 'Offline hello',
      timestamp: DateTime.utc(2026, 1, 1, 10),
      status: MessageStatus.sent,
      isLocalSender: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MessageBubble(message: message)),
      ),
    );

    expect(find.text('Offline hello'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}

