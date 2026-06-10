import 'package:http/http.dart' as http;

class Contract {
  final String id;
  final String employeeName;
  final String position;
  final String department;
  final String value;
  final String startDate;
  final String endDate;

  const Contract({
    required this.id,
    required this.employeeName,
    required this.position,
    required this.department,
    required this.value,
    required this.startDate,
    required this.endDate,
  });

  // حالة العقد بناءً على تاريخ الانتهاء
  ContractStatus get status {
    if (endDate.isEmpty) return ContractStatus.unknown;
    try {
      final parts = endDate.split('/');
      if (parts.length != 3) return ContractStatus.unknown;
      final end = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      final now = DateTime.now();
      final diff = end.difference(now).inDays;
      if (diff < 0) return ContractStatus.expired;
      if (diff <= 30) return ContractStatus.expiringSoon;
      return ContractStatus.active;
    } catch (_) {
      return ContractStatus.unknown;
    }
  }
}

enum ContractStatus { active, expiringSoon, expired, unknown }

class ContractService {
  static const String _sheetId =
      '18Mcf2hWZTBialBUQ_tWPXbshFTInmDtSo-XbaLMWMSg';

  static Future<List<Contract>> fetchContracts(String nationalId) async {
    try {
      final uri = Uri.https(
        'docs.google.com',
        '/spreadsheets/d/$_sheetId/gviz/tq',
        {'tqx': 'out:csv', 'sheet': 'con'},
      );
      final res =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return _parse(res.body, nationalId);
    } catch (_) {}
    return [];
  }

  static List<Contract> _parse(String body, String nationalId) {
    var raw = body;
    if (raw.startsWith('﻿')) raw = raw.substring(1);

    final result = <Contract>[];
    for (final line in raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)) {
      final c = _cols(line);
      if (c.isEmpty) continue;
      // العمود A = id (رقم الهوية)
      if (c[0] != nationalId) continue;
      String g(int i) => i < c.length ? c[i] : '';
      result.add(Contract(
        id:           g(0),
        employeeName: g(1),
        position:     g(2),
        department:   g(3),
        value:        g(4),
        startDate:    g(5),
        endDate:      g(6),
      ));
    }
    return result;
  }

  static List<String> _cols(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool q = false;
    for (final ch in line.runes) {
      final c = String.fromCharCode(ch);
      if (c == '"') {
        q = !q;
      } else if (c == ',' && !q) {
        result.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString().trim());
    return result;
  }
}
