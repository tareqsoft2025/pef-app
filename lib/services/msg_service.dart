import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MsgService {
  static const String _sheetId =
      '18Mcf2hWZTBialBUQ_tWPXbshFTInmDtSo-XbaLMWMSg';

  static Future<List<HrMessage>> fetchMessages(String userId) async {
    try {
      final uri = Uri.https(
        'docs.google.com',
        '/spreadsheets/d/$_sheetId/gviz/tq',
        {'tqx': 'out:csv', 'sheet': 'msg'},
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _parseCsv(response.body, userId).reversed.toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<int> getUnseenCount(String userId) async {
    try {
      final msgs = await fetchMessages(userId);
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getInt('msg_seen_${userId}') ?? 0;
      final unseen = msgs.length - seen;
      return unseen > 0 ? unseen : 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> markAllSeen(String userId, int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('msg_seen_${userId}', total);
  }

  static List<HrMessage> _parseCsv(String body, String userId) {
    var raw = body;
    if (raw.startsWith('﻿')) raw = raw.substring(1);

    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final result = <HrMessage>[];
    for (final line in lines) {
      final c = _cols(line);
      if (c.length >= 2 && c[0] == userId && c[1].isNotEmpty) {
        result.add(HrMessage(text: c[1]));
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

class HrMessage {
  final String text;
  const HrMessage({required this.text});
}
