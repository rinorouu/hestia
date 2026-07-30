import 'package:intl/intl.dart';

String formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  final exponent = (bytes.toString().length - 1) ~/ 3;
  final i = exponent.clamp(0, units.length - 1);
  final value = bytes / _pow1024(i);
  return '${value.toStringAsFixed(i == 0 ? 0 : decimals)} ${units[i]}';
}

double _pow1024(int power) {
  var result = 1.0;
  for (var i = 0; i < power; i++) {
    result *= 1024;
  }
  return result;
}

final DateFormat _dateTimeFormat = DateFormat('d MMM y, HH:mm');
final DateFormat _dateFormat = DateFormat('d MMM y');

String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt.toLocal());

String formatDate(DateTime dt) => _dateFormat.format(dt.toLocal());
