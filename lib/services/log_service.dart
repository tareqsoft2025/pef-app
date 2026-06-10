import 'gas_client.dart';

class LogService {
  static Future<void> logAttempt({
    required String username,
    required String location,
    required bool success,
  }) async {
    final now = DateTime.now();
    await GasClient.post({
      'sheet': 'reg',
      'username': username,
      'date': _fmt(now),
      'time': _time(now),
      'location': location,
      'status': success ? '✓ ناجح' : '✗ فاشل',
    });
  }

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  static String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}
