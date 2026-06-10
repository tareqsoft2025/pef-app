import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _kUsername = 'auth_username';
  static const _kPassword = 'auth_password';
  static const _kName = 'auth_name';

  static Future<void> saveCredentials({
    required String username,
    required String password,
    required String name,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUsername, username);
    await p.setString(_kPassword, password);
    await p.setString(_kName, name);
  }

  static Future<SavedCredentials?> loadCredentials() async {
    final p = await SharedPreferences.getInstance();
    final u = p.getString(_kUsername);
    final pw = p.getString(_kPassword);
    final n = p.getString(_kName);
    if (u != null && pw != null) {
      return SavedCredentials(username: u, password: pw, name: n ?? '');
    }
    return null;
  }

  static Future<void> clearCredentials() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kUsername);
    await p.remove(_kPassword);
    await p.remove(_kName);
  }
}

class SavedCredentials {
  final String username, password, name;
  const SavedCredentials({
    required this.username,
    required this.password,
    required this.name,
  });
}
