import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Guarda la sesión cifrada; en Android la llave vive en Android Keystore.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required this.persistSessionKey});

  final String persistSessionKey;
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {
    // Mueve la sesión que versiones anteriores dejaron sin cifrar.
    final anterior = SharedPreferencesLocalStorage(persistSessionKey: persistSessionKey);
    await anterior.initialize();
    final sesion = await anterior.accessToken();
    if (sesion == null) return;
    if (!await hasAccessToken()) await persistSession(sesion);
    await anterior.removePersistedSession();
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: persistSessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: persistSessionKey);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: persistSessionKey, value: persistSessionString);
}
