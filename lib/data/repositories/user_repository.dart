import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/user_profile.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository(this._isar, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Isar _isar;
  final Uuid _uuid;

  Future<UserProfile?> getLocalProfile() async {
    final model = await _isar.userModels.filter().isLocalEqualTo(true).findFirst();
    return model?.toProfile();
  }

  Future<UserProfile> createLocalProfile(String username) async {
    final profile = UserProfile(deviceId: _uuid.v4(), username: username.trim());
    await saveLocalProfile(profile);
    return profile;
  }

  Future<void> saveLocalProfile(UserProfile profile) async {
    final existing = await _isar.userModels.filter().deviceIdEqualTo(profile.deviceId).findFirst();
    final model = UserModel.fromProfile(profile, isLocal: true);
    if (existing != null) model.id = existing.id;
    await _isar.writeTxn(() => _isar.userModels.put(model));
  }

  Future<void> savePeerProfile(UserProfile profile) async {
    final existing = await _isar.userModels.filter().deviceIdEqualTo(profile.deviceId).findFirst();
    final model = UserModel.fromProfile(profile, isLocal: false);
    if (existing != null) model.id = existing.id;
    await _isar.writeTxn(() => _isar.userModels.put(model));
  }

  Future<UserProfile?> findByDeviceId(String deviceId) async {
    return (await _isar.userModels.filter().deviceIdEqualTo(deviceId).findFirst())?.toProfile();
  }
}

