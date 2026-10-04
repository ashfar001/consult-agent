import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../data/db/daos.dart';

/// Stores small secrets (the auth token) at rest.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Encrypts values with Windows DPAPI (CurrentUser scope) and keeps the
/// ciphertext in the local DB kv table, so the token is unreadable by other
/// Windows accounts or if the DB file is copied to another machine.
class DpapiSecureStore implements SecureStore {
  DpapiSecureStore(this._kv);

  final KvDao _kv;

  static const _cryptProtectUiForbidden = 0x1;

  @override
  Future<String?> read(String key) async {
    final stored = await _kv.get('secure:$key');
    if (stored == null) return null;
    try {
      return utf8.decode(_unprotect(base64Decode(stored)));
    } on Object {
      // Corrupt or from another user/machine: treat as absent.
      await delete(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) =>
      _kv.put('secure:$key', base64Encode(_protect(utf8.encode(value))));

  @override
  Future<void> delete(String key) => _kv.remove('secure:$key');

  static Uint8List _protect(List<int> plain) => _run(plain, encrypt: true);

  static Uint8List _unprotect(List<int> cipher) => _run(cipher, encrypt: false);

  static Uint8List _run(List<int> input, {required bool encrypt}) =>
      using((arena) {
        final inBuf = arena<Uint8>(input.isEmpty ? 1 : input.length);
        inBuf.asTypedList(input.length).setAll(0, input);
        final inBlob = arena<CRYPT_INTEGER_BLOB>()
          ..ref.cbData = input.length
          ..ref.pbData = inBuf;
        final outBlob = arena<CRYPT_INTEGER_BLOB>();

        final result = encrypt
            ? CryptProtectData(
                inBlob, null, null, null, _cryptProtectUiForbidden, outBlob)
            : CryptUnprotectData(
                inBlob, null, null, null, _cryptProtectUiForbidden, outBlob);
        if (!result.value) {
          throw OSError('DPAPI failed', result.error);
        }
        try {
          return Uint8List.fromList(
            outBlob.ref.pbData.asTypedList(outBlob.ref.cbData),
          );
        } finally {
          LocalFree(HLOCAL(outBlob.ref.pbData));
        }
      });
}

/// Unencrypted store for tests and non-Windows hosts.
class PlainSecureStore implements SecureStore {
  PlainSecureStore(this._kv);

  final KvDao _kv;

  @override
  Future<String?> read(String key) => _kv.get('secure:$key');

  @override
  Future<void> write(String key, String value) => _kv.put('secure:$key', value);

  @override
  Future<void> delete(String key) => _kv.remove('secure:$key');
}

SecureStore createSecureStore(KvDao kv) =>
    Platform.isWindows ? DpapiSecureStore(kv) : PlainSecureStore(kv);
