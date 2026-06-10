class ChatEntity {
  const ChatEntity({
    required this.id,
    required this.peerDeviceId,
    required this.peerName,
    required this.peerAddress,
    required this.lastMessage,
    required this.lastActivity,
    required this.unreadCount,
  });

  final String id;
  final String peerDeviceId;
  final String peerName;
  final String peerAddress;
  final String lastMessage;
  final DateTime lastActivity;
  final int unreadCount;

  ChatEntity copyWith({
    String? id,
    String? peerDeviceId,
    String? peerName,
    String? peerAddress,
    String? lastMessage,
    DateTime? lastActivity,
    int? unreadCount,
  }) {
    return ChatEntity(
      id: id ?? this.id,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      peerName: peerName ?? this.peerName,
      peerAddress: peerAddress ?? this.peerAddress,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

