import 'package:intl/intl.dart';

import 'json_utils.dart';
import 'project.dart';

class TaskReport {
  const TaskReport({required this.taskId, required this.status, this.note = ''});

  factory TaskReport.fromJson(Json json) => TaskReport(
        taskId: asString(json['task_id']),
        status: taskStatusFromString(asString(json['status'])),
        note: asString(json['note']),
      );

  final String taskId;
  final TaskStatus status;
  final String note;

  Json toJson() => {
        'task_id': taskId,
        'status': taskStatusToString(status),
        'note': note,
      };
}

/// Body of `POST /agent/daily-report`.
class DailyReport {
  const DailyReport({
    required this.clientId,
    required this.date,
    required this.summary,
    required this.notes,
    required this.tasks,
    required this.fileIds,
  });

  factory DailyReport.fromJson(Json json) => DailyReport(
        clientId: asString(json['client_id']),
        date: DateTime.parse(asString(json['date'])),
        summary: asString(json['summary']),
        notes: asString(json['notes']),
        tasks: asJsonList(json['tasks']).map(TaskReport.fromJson).toList(),
        fileIds: json['file_ids'] is List
            ? (json['file_ids'] as List).map((e) => '$e').toList()
            : const [],
      );

  final String clientId;

  /// Local calendar day being reported.
  final DateTime date;
  final String summary;
  final String notes;
  final List<TaskReport> tasks;
  final List<String> fileIds;

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  Json toJson() => {
        'client_id': clientId,
        'date': _dateFmt.format(date),
        'summary': summary,
        'notes': notes,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'file_ids': fileIds,
      };
}

/// Response of `GET /agent/my-hours/today`.
class HoursToday {
  const HoursToday({
    required this.activeSecs,
    required this.idleSecs,
    required this.apps,
    required this.projects,
  });

  factory HoursToday.fromJson(Json json) => HoursToday(
        activeSecs: asInt(json['active_secs']),
        idleSecs: asInt(json['idle_secs']),
        apps: asIntMap(json['apps']),
        projects:
            asJsonList(json['projects']).map(ProjectHours.fromJson).toList(),
      );

  final int activeSecs;
  final int idleSecs;
  final Map<String, int> apps;
  final List<ProjectHours> projects;
}

class ProjectHours {
  const ProjectHours({
    required this.projectId,
    required this.code,
    required this.activeSecsToday,
    required this.myUsedSeconds,
    required this.myAllocatedHours,
  });

  factory ProjectHours.fromJson(Json json) => ProjectHours(
        projectId: asString(json['project_id']),
        code: asString(json['code']),
        activeSecsToday: asInt(json['active_secs']),
        myUsedSeconds: asInt(json['my_used_seconds']),
        myAllocatedHours: asDouble(json['my_allocated_hours']),
      );

  final String projectId;
  final String code;
  final int activeSecsToday;
  final int myUsedSeconds;
  final double myAllocatedHours;
}
