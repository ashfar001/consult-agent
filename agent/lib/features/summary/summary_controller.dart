import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/models/models.dart';
import '../../domain/hour_limits.dart';
import '../../services/logging.dart';

/// The report date shown on the Summary screen (yyyy-MM-dd).
class SummaryDateNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? date) => state = date;
}

final summaryDateProvider =
    NotifierProvider<SummaryDateNotifier, String?>(SummaryDateNotifier.new);

class ProjectSummary {
  const ProjectSummary({
    required this.code,
    required this.name,
    required this.todayActiveSecs,
    required this.usage,
    required this.estimate,
  });

  final String code;
  final String name;
  final int todayActiveSecs;
  final HourUsage usage;

  /// Server figures were unreachable; numbers are computed from local data.
  final bool estimate;
}

class SummaryState {
  const SummaryState({
    this.loading = true,
    this.date = '',
    this.activeSecs = 0,
    this.idleSecs = 0,
    this.overtimeSecs = 0,
    this.breakSecs = 0,
    this.apps = const [],
    this.projects = const [],
  });

  final bool loading;
  final String date;

  /// Normal-hours active time.
  final int activeSecs;
  final int idleSecs;
  final int overtimeSecs;
  final int breakSecs;
  final List<MapEntry<String, int>> apps;
  final List<ProjectSummary> projects;
}

/// Today's totals from local data (always available, even offline), with the
/// remaining hours taken from the server when it can be reached.
class SummaryController extends Notifier<SummaryState> {
  static final _dayFmt = DateFormat('yyyy-MM-dd');

  @override
  SummaryState build() => const SummaryState();

  Future<void> load() async {
    final db = ref.read(dbProvider);
    final date =
        ref.read(summaryDateProvider) ?? _dayFmt.format(ref.read(clockProvider)());
    state = SummaryState(date: date);
    final day = _dayFmt.parse(date);

    // Let the server see today's time before asking for hours left.
    var reachable = false;
    try {
      reachable = await ref
          .read(syncWorkerProvider)
          .syncOnce(ignoreBackoff: true)
          .timeout(const Duration(seconds: 6));
    } on Object {
      reachable = false;
    }

    final rows = await db.sessionDao
        .heartbeatsBetween(day, day.add(const Duration(days: 1)));
    var active = 0, idle = 0, overtime = 0;
    final apps = <String, int>{};
    final perProject = <String, int>{};
    final perProjectNormal = <String, int>{};
    for (final r in rows) {
      final isOvertime = r.session.kind == 'overtime';
      idle += r.hb.idleSecs;
      if (isOvertime) {
        overtime += r.hb.activeSecs;
      } else {
        active += r.hb.activeSecs;
        perProjectNormal.update(
          r.session.projectId,
          (v) => v + r.hb.activeSecs,
          ifAbsent: () => r.hb.activeSecs,
        );
      }
      perProject.update(
        r.session.projectId,
        (v) => v + r.hb.activeSecs,
        ifAbsent: () => r.hb.activeSecs,
      );
      final m = jsonDecode(r.hb.appsJson) as Map<String, dynamic>;
      m.forEach((k, v) => apps.update(k, (x) => x + asInt(v), ifAbsent: () => asInt(v)));
    }

    final breaks = await db.breakDao.forDay(date);
    final breakSecs = breaks.fold<int>(
      0,
      (a, b) => a + ((b.endedAt ?? b.startedAt).difference(b.startedAt).inSeconds),
    );

    // Hours left: fresh from the server if possible, else the saved list.
    var projects = (await db.projectCacheDao.load()).projects;
    var estimate = true;
    if (reachable) {
      try {
        projects = await ref
            .read(apiClientProvider)
            .myProjects()
            .timeout(const Duration(seconds: 5));
        estimate = false;
      } on Object catch (e) {
        log.w('Summary: could not refresh hours ($e)');
      }
    }
    final summaries = <ProjectSummary>[];
    for (final p in projects.where((p) => perProject.containsKey(p.id))) {
      final unsynced = await db.sessionDao.unsyncedActiveSecs(p.id);
      summaries.add(ProjectSummary(
        code: p.code,
        name: p.name,
        todayActiveSecs: perProject[p.id] ?? 0,
        // Saved list predates today's work; add it back in.
        usage: HourUsage.ofProject(
          p,
          unsyncedSecs: estimate ? perProjectNormal[p.id] ?? 0 : unsynced,
        ),
        estimate: estimate,
      ));
    }

    state = SummaryState(
      loading: false,
      date: date,
      activeSecs: active,
      idleSecs: idle,
      overtimeSecs: overtime,
      breakSecs: breakSecs,
      apps: apps.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      projects: summaries,
    );
  }
}

final summaryControllerProvider =
    NotifierProvider<SummaryController, SummaryState>(SummaryController.new);
