import 'package:http/http.dart' as http;

class AuthService {
  static const String _sheetId =
      '18Mcf2hWZTBialBUQ_tWPXbshFTInmDtSo-XbaLMWMSg';

  static Future<LoginResponse> login(String username, String password) async {
    final url =
        'https://docs.google.com/spreadsheets/d/$_sheetId/gviz/tq?tqx=out:csv&sheet=user';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final lines = response.body
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

        for (final line in lines) {
          final cols = _parseCsvLine(line);
          if (cols.length >= 2) {
            final sheetUser = cols[0].trim();
            final sheetPass = cols[1].trim();
            final sheetName = cols.length >= 3 ? cols[2].trim() : '';

            if (sheetUser == username && sheetPass == password) {
              return LoginResponse.success(sheetName);
            }
          }
        }
        return LoginResponse.wrongCredentials();
      } else {
        return LoginResponse.networkError();
      }
    } catch (_) {
      return LoginResponse.networkError();
    }
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString());
    return result;
  }
}

enum AuthStatus { success, wrongCredentials, networkError }

class LoginResponse {
  final AuthStatus status;
  final String employeeName;

  const LoginResponse._({required this.status, this.employeeName = ''});

  factory LoginResponse.success(String name) =>
      LoginResponse._(status: AuthStatus.success, employeeName: name);

  factory LoginResponse.wrongCredentials() =>
      const LoginResponse._(status: AuthStatus.wrongCredentials);

  factory LoginResponse.networkError() =>
      const LoginResponse._(status: AuthStatus.networkError);
}
