import 'json_utils.dart';

class Worker {
  const Worker({
    required this.id,
    required this.employeeId,
    required this.name,
    this.role,
  });

  factory Worker.fromJson(Json json) => Worker(
    id: asString(json['id']),
    employeeId: asString(json['employee_id']),
    name: asString(json['name']),
    role: asStringOrNull(json['role']),
  );

  final String id;
  final String employeeId;
  final String name;
  final String? role;

  Json toJson() => {
    'id': id,
    'employee_id': employeeId,
    'name': name,
    if (role != null) 'role': role,
  };
}

/// Result of `POST /agent/login`.
class LoginResult {
  const LoginResult({required this.token, required this.worker});

  factory LoginResult.fromJson(Json json) => LoginResult(
    token: asString(json['token']),
    worker: Worker.fromJson(json['worker'] as Json),
  );

  final String token;
  final Worker worker;
}

enum DeviceStatus { pending, approved }

DeviceStatus deviceStatusFromString(String s) =>
    s == 'approved' ? DeviceStatus.approved : DeviceStatus.pending;
