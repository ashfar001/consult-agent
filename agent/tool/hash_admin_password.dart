// Generates the config.json values for the super-admin exit password.
//
//   dart run tool/hash_admin_password.dart
//
// Paste the two printed lines into %ProgramData%\ConsultAgent\config.json.
// The password is not stored anywhere; keep it in your password manager.
import 'dart:io';
import 'dart:math';

import 'package:consult_agent/domain/admin_gate.dart';

void main(List<String> args) {
  stdout.write('Admin exit password: ');
  stdin.echoMode = false;
  final password = stdin.readLineSync() ?? '';
  stdin.echoMode = true;
  stdout.writeln();
  if (password.length < 8) {
    stderr.writeln('Use at least 8 characters.');
    exitCode = 1;
    return;
  }
  final rng = Random.secure();
  final salt = List.generate(
    16,
    (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  stdout.writeln('"admin_exit_salt": "$salt",');
  stdout.writeln(
    '"admin_exit_hash": "${AdminGate.hashPassword(salt, password)}",',
  );
}
