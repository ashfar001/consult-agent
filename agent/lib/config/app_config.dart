import 'package:path/path.dart' as p;

import '../domain/app_classifier.dart';

/// Runtime configuration, loaded from `%ProgramData%\ConsultAgent\config.json`.
///
/// Holds no secrets: the API base URL is public and auth tokens live in the
/// encrypted secure store.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.mockApi,
    required this.companyName,
    required this.idleThresholdSecs,
    required this.pollIntervalSecs,
    required this.heartbeatIntervalSecs,
    required this.projectsRoot,
    required this.fallbackProjectsRoot,
    required this.dataDir,
    required this.logDir,
    required this.mockFailureRate,
    required this.mockLatencyMs,
    this.breakAllowanceSecs = 3600,
    this.breakMaxPieces = 2,
    this.workdayEnd = '17:00',
    this.launchPollSecs = 3,
    this.promptRetryMins = 5,
    this.maxUploadFileBytes = 200 * 1024 * 1024,
    this.adminExitHash = '',
    this.adminExitSalt = '',
  });

  /// Defaults for a machine whose shared data lives under [programDataDir].
  factory AppConfig.defaults({
    required String programDataDir,
    required String userProfileDir,
  }) {
    final base = p.join(programDataDir, 'ConsultAgent');
    return AppConfig(
      apiBaseUrl: 'https://www.app.squarem.in',
      mockApi: false,
      companyName: 'SQUAREM',
      idleThresholdSecs: 300,
      pollIntervalSecs: 5,
      heartbeatIntervalSecs: 60,
      projectsRoot: r'D:\Projects',
      fallbackProjectsRoot: p.join(userProfileDir, 'Projects'),
      dataDir: p.join(base, 'data'),
      logDir: p.join(base, 'logs'),
      mockFailureRate: 0.15,
      mockLatencyMs: 500,
    );
  }

  final String apiBaseUrl;
  final bool mockApi;
  final String companyName;
  final int idleThresholdSecs;
  final int pollIntervalSecs;
  final int heartbeatIntervalSecs;
  final String projectsRoot;
  final String fallbackProjectsRoot;
  final String dataDir;
  final String logDir;

  /// Probability (0..1) that a mock API call fails with a network error.
  final double mockFailureRate;

  /// Upper bound of simulated mock latency; actual latency is 40–100% of it.
  final int mockLatencyMs;

  /// Lunch break allowance per day, and how many pieces it can be split in.
  final int breakAllowanceSecs;
  final int breakMaxPieces;

  /// Local time (HH:mm) when normal hours end; later work is overtime.
  final String workdayEnd;

  /// How often running CAD processes are checked, and how long a dismissed
  /// project prompt stays away.
  final int launchPollSecs;
  final int promptRetryMins;

  /// Larger files are skipped by the daily backup.
  final int maxUploadFileBytes;

  /// Salted hash of the super-admin exit password (see tool/hash_admin_password.dart).
  /// Empty means no password is set and the agent cannot be exited from the UI.
  final String adminExitHash;
  final String adminExitSalt;

  /// Processes whose start raises the project prompt. Demo (mock) builds also
  /// accept Notepad and Paint so the flow can be tried on a PC without CAD.
  Set<String> get triggerApps => mockApi
      ? {...cadExecutables, 'notepad.exe', 'mspaint.exe'}
      : cadExecutables;

  /// Returns a copy with any keys present in [json] overriding this config.
  AppConfig mergeJson(Map<String, dynamic> json) {
    T pick<T>(String key, T current) {
      final v = json[key];
      if (v == null) return current;
      if (T == double && v is num) return v.toDouble() as T;
      if (T == int && v is num) return v.toInt() as T;
      return v is T ? v : current;
    }

    return AppConfig(
      apiBaseUrl: pick('api_base_url', apiBaseUrl),
      mockApi: pick('mock_api', mockApi),
      companyName: pick('company_name', companyName),
      idleThresholdSecs: pick('idle_threshold_secs', idleThresholdSecs),
      pollIntervalSecs: pick('poll_interval_secs', pollIntervalSecs),
      heartbeatIntervalSecs: pick(
        'heartbeat_interval_secs',
        heartbeatIntervalSecs,
      ),
      projectsRoot: pick('projects_root', projectsRoot),
      fallbackProjectsRoot: pick(
        'fallback_projects_root',
        fallbackProjectsRoot,
      ),
      dataDir: pick('data_dir', dataDir),
      logDir: pick('log_dir', logDir),
      mockFailureRate: pick('mock_failure_rate', mockFailureRate),
      mockLatencyMs: pick('mock_latency_ms', mockLatencyMs),
      breakAllowanceSecs: pick('break_allowance_secs', breakAllowanceSecs),
      breakMaxPieces: pick('break_max_pieces', breakMaxPieces),
      workdayEnd: pick('workday_end', workdayEnd),
      launchPollSecs: pick('launch_poll_secs', launchPollSecs),
      promptRetryMins: pick('prompt_retry_mins', promptRetryMins),
      maxUploadFileBytes: pick('max_upload_file_bytes', maxUploadFileBytes),
      adminExitHash: pick('admin_exit_hash', adminExitHash),
      adminExitSalt: pick('admin_exit_salt', adminExitSalt),
    );
  }

  AppConfig withMockApi(bool value) =>
      mergeJson(<String, dynamic>{'mock_api': value});

  Map<String, dynamic> toJson() => {
    'api_base_url': apiBaseUrl,
    'mock_api': mockApi,
    'company_name': companyName,
    'idle_threshold_secs': idleThresholdSecs,
    'poll_interval_secs': pollIntervalSecs,
    'heartbeat_interval_secs': heartbeatIntervalSecs,
    'projects_root': projectsRoot,
    'fallback_projects_root': fallbackProjectsRoot,
    'data_dir': dataDir,
    'log_dir': logDir,
    'mock_failure_rate': mockFailureRate,
    'mock_latency_ms': mockLatencyMs,
    'break_allowance_secs': breakAllowanceSecs,
    'break_max_pieces': breakMaxPieces,
    'workday_end': workdayEnd,
    'launch_poll_secs': launchPollSecs,
    'prompt_retry_mins': promptRetryMins,
    'max_upload_file_bytes': maxUploadFileBytes,
    'admin_exit_hash': adminExitHash,
    'admin_exit_salt': adminExitSalt,
  };
}
