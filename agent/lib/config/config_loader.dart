import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_config.dart';

/// `--dart-define=MOCK_API=true` at build/run time.
const bool _mockApiDefine = bool.fromEnvironment('MOCK_API');

/// Loads [AppConfig] from `<programData>\ConsultAgent\config.json`.
///
/// A missing file yields defaults and a sample file is written (best effort,
/// since standard users may not be able to write ProgramData). A malformed
/// file is logged by the caller and defaults are used.
class ConfigLoader {
  ConfigLoader({
    String? programDataDir,
    String? userProfileDir,
    Map<String, String>? environment,
    bool? mockDefine,
  }) : _env = environment ?? Platform.environment,
       _mockDefine = mockDefine ?? _mockApiDefine,
       _programDataDir = programDataDir,
       _userProfileDir = userProfileDir;

  final Map<String, String> _env;
  final bool _mockDefine;
  final String? _programDataDir;
  final String? _userProfileDir;

  String get programDataDir =>
      _programDataDir ?? _env['ProgramData'] ?? r'C:\ProgramData';

  String get userProfileDir =>
      _userProfileDir ??
      _env['USERPROFILE'] ??
      _env['HOME'] ??
      Directory.systemTemp.path;

  String get configPath =>
      p.join(programDataDir, 'ConsultAgent', 'config.json');

  /// Errors encountered while loading, for logging once a logger exists.
  final List<String> warnings = [];

  AppConfig load() {
    var config = AppConfig.defaults(
      programDataDir: programDataDir,
      userProfileDir: userProfileDir,
    );
    final file = File(configPath);
    if (file.existsSync()) {
      try {
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is Map<String, dynamic>) {
          config = config.mergeJson(decoded);
        } else {
          warnings.add('config.json is not a JSON object; using defaults');
        }
      } on FormatException catch (e) {
        warnings.add('config.json is malformed ($e); using defaults');
      }
    } else {
      _writeSample(file, config);
    }

    final envMock = _env['MOCK_API']?.toLowerCase();
    if (_mockDefine || envMock == 'true' || envMock == '1') {
      config = config.withMockApi(true);
    }
    return config;
  }

  void _writeSample(File file, AppConfig config) {
    try {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(config.toJson()),
      );
    } on FileSystemException catch (e) {
      warnings.add('Could not write sample config: ${e.message}');
    }
  }
}
