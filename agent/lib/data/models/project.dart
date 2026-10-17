import 'json_utils.dart';

enum OverrunMode { allow, block }

enum TaskStatus { todo, inProgress, completed, blocked }

TaskStatus taskStatusFromString(String s) => switch (s) {
  'in_progress' => TaskStatus.inProgress,
  'completed' => TaskStatus.completed,
  'blocked' => TaskStatus.blocked,
  _ => TaskStatus.todo,
};

String taskStatusToString(TaskStatus s) => switch (s) {
  TaskStatus.todo => 'todo',
  TaskStatus.inProgress => 'in_progress',
  TaskStatus.completed => 'completed',
  TaskStatus.blocked => 'blocked',
};

class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.title,
    required this.status,
    required this.allocatedHours,
  });

  factory ProjectTask.fromJson(Json json) => ProjectTask(
    id: asString(json['id']),
    title: asString(json['title']),
    status: taskStatusFromString(asString(json['status'])),
    allocatedHours: asDouble(json['allocated_hours']),
  );

  final String id;
  final String title;
  final TaskStatus status;
  final double allocatedHours;

  bool get isOpen => status != TaskStatus.completed;

  ProjectTask copyWith({TaskStatus? status}) => ProjectTask(
    id: id,
    title: title,
    status: status ?? this.status,
    allocatedHours: allocatedHours,
  );

  Json toJson() => {
    'id': id,
    'title': title,
    'status': taskStatusToString(status),
    'allocated_hours': allocatedHours,
  };
}

/// A project assigned to the signed-in worker, as returned by
/// `GET /agent/my-projects`. "my_*" fields are this worker's allocation.
class Project {
  const Project({
    required this.id,
    required this.code,
    required this.name,
    required this.client,
    required this.overrunMode,
    required this.folderTemplate,
    required this.myAllocatedHours,
    required this.myUsedSeconds,
    required this.projectTotalHours,
    required this.projectUsedSeconds,
    required this.tasks,
    this.mainFile,
  });

  factory Project.fromJson(Json json) => Project(
    id: asString(json['id']),
    code: asString(json['code']),
    name: asString(json['name']),
    client: asString(json['client']),
    overrunMode: asString(json['overrun_mode']) == 'block'
        ? OverrunMode.block
        : OverrunMode.allow,
    folderTemplate: json['folder_template'] is List
        ? (json['folder_template'] as List).map((e) => '$e').toList()
        : const [],
    myAllocatedHours: asDouble(json['my_allocated_hours']),
    myUsedSeconds: asInt(json['my_used_seconds']),
    projectTotalHours: asDouble(json['project_total_hours']),
    projectUsedSeconds: asInt(json['project_used_seconds']),
    tasks: asJsonList(json['tasks']).map(ProjectTask.fromJson).toList(),
    mainFile: asStringOrNull(json['main_file']),
  );

  final String id;
  final String code;
  final String name;
  final String client;
  final OverrunMode overrunMode;

  /// Subfolders to create; empty means use the agent's default template.
  final List<String> folderTemplate;
  final double myAllocatedHours;
  final int myUsedSeconds;
  final double projectTotalHours;
  final int projectUsedSeconds;
  final List<ProjectTask> tasks;

  /// Optional relative path opened instead of the folder (not in the base
  /// contract; tolerated if the server sends it).
  final String? mainFile;

  List<ProjectTask> get openTasks => tasks.where((t) => t.isOpen).toList();

  Project copyWith({int? myUsedSeconds, List<ProjectTask>? tasks}) => Project(
    id: id,
    code: code,
    name: name,
    client: client,
    overrunMode: overrunMode,
    folderTemplate: folderTemplate,
    myAllocatedHours: myAllocatedHours,
    myUsedSeconds: myUsedSeconds ?? this.myUsedSeconds,
    projectTotalHours: projectTotalHours,
    projectUsedSeconds: projectUsedSeconds,
    tasks: tasks ?? this.tasks,
    mainFile: mainFile,
  );

  Json toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'client': client,
    'overrun_mode': overrunMode.name,
    'folder_template': folderTemplate,
    'my_allocated_hours': myAllocatedHours,
    'my_used_seconds': myUsedSeconds,
    'project_total_hours': projectTotalHours,
    'project_used_seconds': projectUsedSeconds,
    'tasks': tasks.map((t) => t.toJson()).toList(),
    if (mainFile != null) 'main_file': mainFile,
  };
}
