import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class IsarDatabase {
  IsarDatabase._(this.isar);

  final Isar isar;

  static Future<IsarDatabase> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        UserModelSchema,
        ChatModelSchema,
        MessageModelSchema,
      ],
      directory: directory.path,
      name: 'bluechat',
    );
    return IsarDatabase._(isar);
  }
}

