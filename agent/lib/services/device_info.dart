import 'dart:io';

/// Identity of this PC.
class DeviceInfo {
  const DeviceInfo({required this.deviceId, required this.pcName});

  /// Stable UUID generated on first run and stored in the local DB.
  final String deviceId;
  final String pcName;

  static String currentPcName() =>
      Platform.environment['COMPUTERNAME'] ?? Platform.localHostname;
}
