import 'dart:convert';

import '../data/api/api_client.dart';
import '../data/db/daos.dart';
import '../data/models/models.dart';
import 'secure_store.dart';

/// Signs workers in and out and restores the last session on startup.
class AuthService {
  AuthService({
    required ApiClient api,
    required SecureStore secureStore,
    required KvDao kv,
    required this.deviceId,
  }) : _api = api,
       _secure = secureStore,
       _kv = kv;

  final ApiClient _api;
  final SecureStore _secure;
  final KvDao _kv;
  final String deviceId;

  Future<Worker> login({
    required String employeeId,
    required String pin,
  }) async {
    final result = await _api.login(
      employeeId: employeeId.trim(),
      pin: pin,
      deviceId: deviceId,
    );
    _api.token = result.token;
    await _secure.write(KvDao.authTokenKey, result.token);
    await _kv.put(KvDao.workerKey, jsonEncode(result.worker.toJson()));
    return result.worker;
  }

  /// Restores the stored token so queued data can sync before sign-in.
  /// Returns the last worker, or null if there is none.
  Future<Worker?> restore() async {
    final token = await _secure.read(KvDao.authTokenKey);
    final workerJson = await _kv.get(KvDao.workerKey);
    if (token == null || workerJson == null) return null;
    _api.token = token;
    return Worker.fromJson(jsonDecode(workerJson) as Json);
  }

  /// Fully forgets credentials (e.g. a different worker signs in).
  Future<void> forget() async {
    _api.token = null;
    await _secure.delete(KvDao.authTokenKey);
    await _kv.remove(KvDao.workerKey);
  }
}
