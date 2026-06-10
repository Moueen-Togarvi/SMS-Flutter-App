import 'package:flutter/material.dart';

import '../../core/utils/date_formatters.dart';
import '../../domain/entities/chat_entity.dart';

class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  final ChatEntity chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      minVerticalPadding: 12,
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: Text(chat.peerName.isEmpty ? '?' : chat.peerName.substring(0, 1).toUpperCase()),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.peerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(DateFormatters.chatTimestamp(chat.lastActivity), style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chat.lastMessage.isEmpty ? 'Connected device' : chat.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Badge(label: Text(chat.unreadCount.toString())),
          ],
        ],
      ),
    );
  }
}
