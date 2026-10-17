import 'dart:convert';

import 'package:crypto/crypto.dart';

enum AdminResult { ok, wrong, locked, notConfigured }

/// Checks the super-admin exit password against a salted hash.
///
/// The password itself is never stored: IT generates the hash with
/// `dart run tool/hash_admin_password.dart` and puts it in config.json.
/// Three wrong attempts in a row lock further tries for 30 seconds.
class AdminGate {
  AdminGate({
    required this.hash,
    required this.salt,
    required this.clock,
    this.demoPassword,
    this.maxAttempts = 3,
    this.lockout = const Duration(seconds: 30),
  });

  /// Hash rounds; slows down guessing if the config file leaks.
  static const rounds = 20000;

  final String hash;
  final String salt;
  final DateTime Function() clock;

  /// Accepted only when no hash is configured (demo builds).
  final String? demoPassword;
  final int maxAttempts;
  final Duration lockout;

  int _failures = 0;
  DateTime? _lockedUntil;

  static String hashPassword(String salt, String password) {
    final material = utf8.encode('$salt:$password');
    var digest = sha256.convert(material).bytes;
    for (var i = 0; i < rounds; i++) {
      digest = sha256.convert([...digest, ...material]).bytes;
    }
    return digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  bool get isConfigured => hash.isNotEmpty || demoPassword != null;

  /// Seconds until another attempt is allowed (0 when not locked).
  int get lockedSecs {
    final until = _lockedUntil;
    if (until == null) return 0;
    final left = until.difference(clock()).inSeconds + 1;
    return left > 0 ? left : 0;
  }

  AdminResult verify(String password) {
    if (!isConfigured) return AdminResult.notConfigured;
    if (lockedSecs > 0) return AdminResult.locked;

    final ok = hash.isNotEmpty
        ? _same(hashPassword(salt, password), hash.toLowerCase())
        : _same(password, demoPassword!);
    if (ok) {
      _failures = 0;
      _lockedUntil = null;
      return AdminResult.ok;
    }
    _failures++;
    if (_failures >= maxAttempts) {
      _failures = 0;
      _lockedUntil = clock().add(lockout);
    }
    return AdminResult.wrong;
  }

  /// Compares without stopping at the first difference.
  static bool _same(String a, String b) {
    var diff = a.length ^ b.length;
    final n = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
