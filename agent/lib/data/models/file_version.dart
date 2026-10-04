import 'json_utils.dart';

/// A file in a project's remote store (`GET /agent/projects/:id/files`).
class RemoteFile {
  const RemoteFile({
    required this.fileId,
    required this.path,
    required this.version,
    required this.size,
    required this.downloadUrl,
    this.checkedOutBy,
  });

  factory RemoteFile.fromJson(Json json) => RemoteFile(
        fileId: asString(json['file_id']),
        path: asString(json['path']),
        version: asInt(json['version']),
        size: asInt(json['size']),
        checkedOutBy: asStringOrNull(json['checked_out_by']),
        downloadUrl: asString(json['download_url']),
      );

  final String fileId;

  /// Path relative to the project folder, using forward slashes.
  final String path;
  final int version;
  final int size;
  final String? checkedOutBy;
  final String downloadUrl;

  Json toJson() => {
        'file_id': fileId,
        'path': path,
        'version': version,
        'size': size,
        'checked_out_by': checkedOutBy,
        'download_url': downloadUrl,
      };
}

/// Response of `POST /agent/files/upload-url`. Either [url] (single PUT) or
/// [parts] (multipart, one presigned URL per part) is set.
class UploadTarget {
  const UploadTarget({required this.uploadId, this.url, this.parts = const []});

  factory UploadTarget.fromJson(Json json) => UploadTarget(
        uploadId: asString(json['upload_id']),
        url: asStringOrNull(json['url']),
        parts: json['parts'] is List
            ? (json['parts'] as List).map((e) => '$e').toList()
            : const [],
      );

  final String uploadId;
  final String? url;
  final List<String> parts;

  bool get isMultipart => parts.isNotEmpty;
}

/// Response of `POST /agent/files/confirm`.
class FileVersionRef {
  const FileVersionRef({required this.fileId, required this.version});

  factory FileVersionRef.fromJson(Json json) => FileVersionRef(
        fileId: asString(json['file_id']),
        version: asInt(json['version']),
      );

  final String fileId;
  final int version;
}
