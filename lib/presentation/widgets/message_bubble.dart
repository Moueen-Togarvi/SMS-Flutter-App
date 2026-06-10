import 'package:flutter/material.dart';

import '../../core/utils/date_formatters.dart';
import '../../domain/entities/message_entity.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final MessageEntity message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final local = message.isLocalSender;
    final background = local ? scheme.primary : scheme.surfaceContainerHighest;
    final foreground = local ? scheme.onPrimary : scheme.onSurface;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(local ? 18 : 4),
      bottomRight: Radius.circular(local ? 4 : 18),
    );

    return Align(
      alignment: local ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
          decoration: BoxDecoration(color: background, borderRadius: radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(message.text, style: TextStyle(color: foreground, height: 1.35)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormatters.messageTime(message.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground.withValues(alpha: 0.75)),
                  ),
                  if (local) ...[
                    const SizedBox(width: 4),
                    Icon(_statusIcon(message.status), size: 16, color: foreground.withValues(alpha: 0.8)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(MessageStatus status) {
    return switch (status) {
      MessageStatus.sending => Icons.schedule_rounded,
      MessageStatus.sent => Icons.check_rounded,
      MessageStatus.delivered => Icons.done_all_rounded,
      MessageStatus.read => Icons.mark_chat_read_rounded,
    };
  }
}

