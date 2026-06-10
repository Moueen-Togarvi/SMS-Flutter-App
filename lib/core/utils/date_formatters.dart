import 'package:intl/intl.dart';

class DateFormatters {
  const DateFormatters._();

  static final _time = DateFormat('HH:mm');
  static final _shortDate = DateFormat('MMM d');

  static String messageTime(DateTime value) => _time.format(value.toLocal());

  static String chatTimestamp(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    return sameDay ? _time.format(local) : _shortDate.format(local);
  }
}

