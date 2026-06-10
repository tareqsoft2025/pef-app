import 'package:http/http.dart' as http;
import 'gas_client.dart';

class AttendanceService {
  static const String _sheetId =
      '18Mcf2hWZTBialBUQ_tWPXbshFTInmDtSo-XbaLMWMSg';

  static Future<bool> record({
    required String username,
    required String name,
    required String date,
    required String time,
    required String location,
    required String type,
  }) async {
    return GasClient.post({
      'sheet': 'حضور',
      'username': username,
      'name': name,
      'date': date,
      'time': time,
      'location': location,
      'type': type,
    });
  }

  static Future<List<AttendanceRecord>> fetchHistory(String username) async {
    try {
      final uri = Uri.https(
        'docs.google.com',
        '/spreadsheets/d/$_sheetId/gviz/tq',
        {'tqx': 'out:csv', 'sheet': 'حضور'},
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _parseCsv(response.body)
            .where((r) => r.username == username)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<TodayStatus> getTodayStatus(String username) async {
    final today = _todayStr();
    try {
      final uri = Uri.https(
        'docs.google.com',
        '/spreadsheets/d/$_sheetId/gviz/tq',
        {'tqx': 'out:csv', 'sheet': 'حضور'},
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final records = _parseCsv(response.body)
            .where((r) => r.username == username && r.date == today)
            .toList();
        return TodayStatus(
          checkedIn: records.any((r) => r.type == 'حضور'),
          checkedOut: records.any((r) => r.type == 'انصراف'),
        );
      }
    } catch (_) {}
    return const TodayStatus(checkedIn: false, checkedOut: false);
  }

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/'
        '${n.month.toString().padLeft(2, '0')}/${n.year}';
  }

  static List<AttendanceRecord> _parseCsv(String body) {
    var raw = body;
    if (raw.startsWith('﻿')) raw = raw.substring(1);

    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final result = <AttendanceRecord>[];
    for (final line in lines) {
      final c = _cols(line);
      // تحقق أن العمود الأول يشبه رقم هوية (أرقام فقط) وليس رأس جدول
      if (c.length >= 6 && _isId(c[0])) {
        result.add(AttendanceRecord(
          username: c[0], name: c[1], date: c[2],
          time: c[3], location: c[4], type: c[5],
        ));
      }
    }
    return result;
  }

  static bool _isId(String s) =>
      s.isNotEmpty && RegExp(r'^\d+$').hasMatch(s);

  static List<String> _cols(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool q = false;
    for (final ch in line.runes) {
      final c = String.fromCharCode(ch);
      if (c == '"') { q = !q; }
      else if (c == ',' && !q) { result.add(buf.toString().trim()); buf.clear(); }
      else { buf.write(c); }
    }
    result.add(buf.toString().trim());
    return result;
  }
}

class AttendanceRecord {
  final String username, name, date, time, location, type;
  const AttendanceRecord({
    required this.username, required this.name, required this.date,
    required this.time, required this.location, required this.type,
  });
}

class TodayStatus {
  final bool checkedIn, checkedOut;
  const TodayStatus({required this.checkedIn, required this.checkedOut});
}
