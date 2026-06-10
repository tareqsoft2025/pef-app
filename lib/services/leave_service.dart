import 'package:http/http.dart' as http;

class LeaveBalance {
  final String id;
  final List<double> monthly; // 12 شهر

  const LeaveBalance({required this.id, required this.monthly});

  static const double annualEntitlement = 14.0;
  static const double monthlyMax = 14.0 / 12; // 1.1667

  double get total => monthly.fold(0, (a, b) => a + b);
  double get percentage => (total / annualEntitlement * 100).clamp(0, 100);
  int get monthsWithData => monthly.where((v) => v > 0).length;
  double get remaining => (annualEntitlement - total).clamp(0, annualEntitlement);
}

class LeaveService {
  static const String _sheetId =
      '18Mcf2hWZTBialBUQ_tWPXbshFTInmDtSo-XbaLMWMSg';

  static Future<LeaveBalance?> fetchBalance(String nationalId) async {
    try {
      final uri = Uri.https(
        'docs.google.com',
        '/spreadsheets/d/$_sheetId/gviz/tq',
        {'tqx': 'out:csv', 'sheet': 'tak'},
      );
      final res =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return _parse(res.body, nationalId);
    } catch (_) {}
    return null;
  }

  static LeaveBalance? _parse(String body, String nationalId) {
    var raw = body;
    if (raw.startsWith('﻿')) raw = raw.substring(1);

    for (final line in raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)) {
      final c = _cols(line);
      if (c.isEmpty || c[0] != nationalId) continue;

      // أعمدة B–M (indices 1–12) = يناير–ديسمبر
      final monthly = List.generate(12, (i) {
        if (i + 1 >= c.length) return 0.0;
        final raw = c[i + 1].replaceAll('%', '').trim();
        if (raw.isEmpty) return 0.0;
        final val = double.tryParse(raw) ?? 0.0;
        // إذا كانت القيمة نسبة مئوية (> 2) → احسب الأيام
        if (val > 2) return (val / 100) * (14.0 / 12);
        return val;
      });

      return LeaveBalance(id: nationalId, monthly: monthly);
    }
    return null;
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
