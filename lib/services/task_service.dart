import 'package:http/http.dart' as http;
import 'gas_client.dart';

class TaskService {
  static const String _sheetId =
      '18Mcf2hWZTBialBUQ_tWPXbshFTInmDtSo-XbaLMWMSg';

  static Future<bool> submit({
    required String username,
    required String name,
    required String date,
    required String taskType,
    required String departureTime,
    required String returnTime,
    required String reason,
    String authority = '',
    String destination = '',
    String gps = '',
  }) async {
    return GasClient.post({
      'sheet': 'مهام',
      'username': username,
      'name': name,
      'date': date,
      'taskType': taskType,
      'departureTime': departureTime,
      'returnTime': returnTime,
      'reason': reason,
      'authority': authority,
      'destination': destination,
      'gps': gps,
    });
  }

  static Future<List<TaskRecord>> fetchHistory(String username) async {
    try {
      final uri = Uri.https(
        'docs.google.com',
        '/spreadsheets/d/$_sheetId/gviz/tq',
        {'tqx': 'out:csv', 'sheet': 'مهام'},
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _parseCsv(response.body)
            .where((r) => r.username == username)
            .toList()
            .reversed
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static List<TaskRecord> _parseCsv(String body) {
    var raw = body;
    if (raw.startsWith('﻿')) raw = raw.substring(1);

    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final result = <TaskRecord>[];
    for (final line in lines) {
      final c = _cols(line);
      if (c.length >= 7 && _isId(c[0])) {
        result.add(TaskRecord(
          username: c[0],
          name: c[1],
          date: c[2],
          taskType: c[3],
          departureTime: c[4],
          returnTime: c[5],
          reason: c[6],
          authority: c.length > 7 ? c[7] : '',
          destination: c.length > 8 ? c[8] : '',
          gps: c.length > 9 ? c[9] : '',
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

class TaskRecord {
  final String username, name, date, taskType;
  final String departureTime, returnTime, reason;
  final String authority, destination, gps;

  const TaskRecord({
    required this.username,
    required this.name,
    required this.date,
    required this.taskType,
    required this.departureTime,
    required this.returnTime,
    required this.reason,
    this.authority = '',
    this.destination = '',
    this.gps = '',
  });

  bool get isOfficial => taskType == 'رسمية';
}
