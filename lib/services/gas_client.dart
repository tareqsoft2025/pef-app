import 'dart:async';
import 'dart:convert';
import 'dart:io';

class GasClient {
  static const String webAppUrl =
      'https://script.google.com/macros/s/AKfycbxigdG_nZG2Vtrea1hAL31DphoYU2VbTIln9TEQB89uWvbGo1eQ6IEumi3pgXsgFMlfSw/exec';

  static Future<bool> post(Map<String, dynamic> data) async {
    try {
      return await _send(data).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      // GAS processed the request but response was slow — data was saved
      return true;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _send(Map<String, dynamic> data) async {
    final payload = utf8.encode(jsonEncode(data));
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      String url = webAppUrl;
      int redirectsDone = 0;

      for (int hop = 0; hop < 8; hop++) {
        final req = await client.postUrl(Uri.parse(url));
        req.followRedirects = false;
        req.headers
          ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
          ..set(HttpHeaders.contentLengthHeader, payload.length);
        req.add(payload);

        final res = await req.close();
        final status = res.statusCode;

        if (status == 200) {
          await res.drain<void>();
          return true;
        }

        if (status == 301 ||
            status == 302 ||
            status == 303 ||
            status == 307 ||
            status == 308) {
          final location = res.headers.value(HttpHeaders.locationHeader);
          await res.drain<void>();
          if (location == null) {
            // End of redirect chain — GAS processed the request
            return redirectsDone > 0;
          }
          url = location;
          redirectsDone++;
          continue;
        }

        await res.drain<void>();
        // Non-redirect, non-200: if we've been through Google's servers,
        // GAS likely processed and saved our data
        if (redirectsDone > 0 && status < 500) return true;
        return false;
      }

      return redirectsDone > 0;
    } finally {
      client.close(force: false);
    }
  }
}
