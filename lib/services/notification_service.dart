import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _sheetId =
      '18Mcf2hWZTBialBUQ_tWPXbshFTInmDtSo-XbaLMWMSg';
  static const String _prefKey = 'notif_seen_count';

  // جلب جميع الإشعارات من الشيت (الأحدث أولاً)
  static Future<List<NotificationItem>> fetchAll() async {
    try {
      final uri = Uri.https(
        'docs.google.com',
        '/spreadsheets/d/$_sheetId/gviz/tq',
        {'tqx': 'out:csv', 'sheet': 'Notifications'},
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final items = _parseCsv(response.body);
        return items.reversed.toList();
      }
    } catch (_) {}
    return [];
  }

  // عدد الإشعارات غير المقروءة
  static Future<int> getUnseenCount() async {
    try {
      final all = await fetchAll();
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getInt(_prefKey) ?? 0;
      final unseen = all.length - seen;
      return unseen > 0 ? unseen : 0;
    } catch (_) {
      return 0;
    }
  }

  // وضع علامة "مقروء" على جميع الإشعارات الحالية
  static Future<void> markAllSeen(int totalCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, totalCount);
  }

  static List<NotificationItem> _parseCsv(String body) {
    var raw = body;
    if (raw.startsWith('﻿')) raw = raw.substring(1);

    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final result = <NotificationItem>[];
    for (int i = 1; i < lines.length; i++) {
      final c = _cols(lines[i]);
      if (c.length >= 3 && c[0].isNotEmpty) {
        result.add(NotificationItem(
          subject: c[0],
          date: c[1],
          text: c[2],
        ));
      }
    }
    return result;
  }

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

class NotificationItem {
  final String subject, date, text;
  const NotificationItem({
    required this.subject,
    required this.date,
    required this.text,
  });
}
