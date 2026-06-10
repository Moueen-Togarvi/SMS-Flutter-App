class UserProfile {
  const UserProfile({
    required this.deviceId,
    required this.username,
  });

  final String deviceId;
  final String username;

  UserProfile copyWith({
    String? deviceId,
    String? username,
  }) {
    return UserProfile(
      deviceId: deviceId ?? this.deviceId,
      username: username ?? this.username,
    );
  }
}

