import 'package:path/path.dart' as p;

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
  });

  /// Defaults for a machine whose shared data lives under [programDataDir].
  factory AppConfig.defaults({
    required String programDataDir,
    required String userProfileDir,
  }) {
    final base = p.join(programDataDir, 'ConsultAgent');
    return AppConfig(
      apiBaseUrl: 'https://api.example.com',
      mockApi: false,
      companyName: 'Consultancy',
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
      heartbeatIntervalSecs:
          pick('heartbeat_interval_secs', heartbeatIntervalSecs),
      projectsRoot: pick('projects_root', projectsRoot),
      fallbackProjectsRoot:
          pick('fallback_projects_root', fallbackProjectsRoot),
      dataDir: pick('data_dir', dataDir),
      logDir: pick('log_dir', logDir),
      mockFailureRate: pick('mock_failure_rate', mockFailureRate),
      mockLatencyMs: pick('mock_latency_ms', mockLatencyMs),
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
      };
}
