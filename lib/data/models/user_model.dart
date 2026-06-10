import 'package:isar_community/isar.dart';

import '../../domain/entities/user_profile.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String deviceId;

  late String username;

  @Index()
  late bool isLocal;

  late DateTime updatedAt;

  UserProfile toProfile() => UserProfile(deviceId: deviceId, username: username);

  static UserModel fromProfile(UserProfile profile, {required bool isLocal}) {
    return UserModel()
      ..deviceId = profile.deviceId
      ..username = profile.username
      ..isLocal = isLocal
      ..updatedAt = DateTime.now().toUtc();
  }
}

