import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _repository = 'ashfar001/consult-agent';
final agentLatestReleaseApi = Uri.https(
  'api.github.com',
  '/repos/$_repository/releases/latest',
);
final agentReleasesPage = Uri.https('github.com', '/$_repository/releases');

/// The stable releases use vMAJOR.MINOR.PATCH tags. Windows stores each
/// component in a 16-bit field in the executable version resource.
class AgentVersion implements Comparable<AgentVersion> {
  const AgentVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static final _tag = RegExp(
    r'^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$',
  );

  static AgentVersion parseTag(String tag) {
    final match = _tag.firstMatch(tag);
    if (match == null || match.end != tag.length) {
      throw const UpdateException(
        'GitHub returned an invalid release version.',
      );
    }
    final parts = [
      for (var i = 1; i <= 3; i++) int.tryParse(match.group(i)!) ?? 65536,
    ];
    if (parts.any((part) => part < 0 || part > 65535)) {
      throw const UpdateException(
        'GitHub returned an invalid release version.',
      );
    }
    return AgentVersion(parts[0], parts[1], parts[2]);
  }

  @override
  int compareTo(AgentVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}

class AgentRelease {
  const AgentRelease._(this.version, this.url, this.sha256Hex, this.bytes);

  final AgentVersion version;
  final Uri url;
  final String sha256Hex;
  final int bytes;

  static const maxDownloadBytes = 256 * 1024 * 1024;
  static final _digest = RegExp(r'^sha256:([a-fA-F0-9]{64})$');

  /// A missing or malformed asset on a newer stable release is a check
  /// failure. Older releases need no asset validation because they cannot run.
  static AgentRelease? fromJson(Object? json, AgentVersion current) {
    if (json is! Map<String, dynamic> ||
        json['draft'] is! bool ||
        json['prerelease'] is! bool ||
        json['tag_name'] is! String) {
      throw const UpdateException(
        'GitHub returned invalid release information.',
      );
    }
    if (json['draft'] == true || json['prerelease'] == true) return null;

    final version = AgentVersion.parseTag(json['tag_name'] as String);
    if (version.compareTo(current) <= 0) return null;
    final tag = 'v$version';
    final name = 'ConsultAgent-Windows-$tag.zip';
    final assets = json['assets'];
    final matches = assets is List
        ? assets
              .whereType<Map<String, dynamic>>()
              .where((a) => a['name'] == name)
              .toList()
        : const <Map<String, dynamic>>[];
    if (matches.length != 1 || matches.single['state'] != 'uploaded') {
      throw UpdateException('The Windows package for $tag is unavailable.');
    }

    final asset = matches.single;
    final url = Uri.https(
      'github.com',
      '/$_repository/releases/download/$tag/$name',
    );
    // GitHub supplies a canonical URL. A byte-for-byte comparison also rejects
    // user info, alternate ports, queries, fragments, and escaped path aliases.
    if (asset['browser_download_url'] != url.toString()) {
      throw const UpdateException(
        'GitHub returned an unexpected download address.',
      );
    }
    final digest = asset['digest'];
    final match = digest is String ? _digest.firstMatch(digest) : null;
    if (match == null || match.end != (digest as String).length) {
      throw const UpdateException(
        'The Windows package has no valid SHA-256 digest.',
      );
    }
    final bytes = asset['size'];
    if (bytes is! int || bytes <= 0 || bytes > maxDownloadBytes) {
      throw const UpdateException(
        'The Windows package has an invalid download size.',
      );
    }
    return AgentRelease._(version, url, match.group(1)!.toLowerCase(), bytes);
  }
}

class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Uses an independent, unauthenticated HTTPS client for the public release.
/// In particular, this never inherits the employee API client's headers.
class AgentReleaseClient {
  static const _timeout = Duration(seconds: 20);
  static const _maxMetadataBytes = 1024 * 1024;
  static final _assetPath = RegExp(
    r'^/github-production-release-asset(?:-2e65be)?/[0-9]+/[^/]+$',
  );
  static const _assetHosts = {
    'release-assets.githubusercontent.com',
    'objects.githubusercontent.com',
  };

  Future<AgentRelease?> latest(AgentVersion current) async {
    final client = _client();
    try {
      final response = await _get(
        client,
        agentLatestReleaseApi,
        accept: 'application/vnd.github+json',
      );
      if (response.statusCode != HttpStatus.ok) {
        throw UpdateException(
          'GitHub update check returned HTTP ${response.statusCode}.',
        );
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(_timeout)) {
        if (bytes.length + chunk.length > _maxMetadataBytes) {
          throw const UpdateException(
            'GitHub returned too much release information.',
          );
        }
        bytes.addAll(chunk);
      }
      return AgentRelease.fromJson(jsonDecode(utf8.decode(bytes)), current);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> download(
    AgentRelease release,
    File destination,
    void Function(double) onProgress,
  ) async {
    final client = _client();
    try {
      var response = await _get(client, release.url);
      for (
        var redirects = 0;
        response.isRedirect && redirects < 3;
        redirects++
      ) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        final target = location == null ? null : Uri.tryParse(location);
        if (target == null || !isTrustedAssetRedirect(target)) {
          throw const UpdateException(
            'GitHub returned an unexpected download redirect.',
          );
        }
        await response.drain<void>().timeout(_timeout);
        response = await _get(client, target);
      }
      if (response.statusCode != HttpStatus.ok) {
        throw UpdateException(
          'GitHub download returned HTTP ${response.statusCode}.',
        );
      }
      if (response.contentLength >= 0 &&
          response.contentLength != release.bytes) {
        throw const UpdateException(
          'The download size does not match the release.',
        );
      }

      var received = 0;
      final file = await destination.open(mode: FileMode.writeOnly);
      try {
        await for (final chunk in response.timeout(_timeout)) {
          received += chunk.length;
          if (received > release.bytes) {
            throw const UpdateException(
              'The download size does not match the release.',
            );
          }
          await file.writeFrom(chunk);
          onProgress(received / release.bytes);
        }
      } finally {
        await file.close();
      }
      if (received != release.bytes) {
        throw const UpdateException('The download is incomplete.');
      }
      await verifyDownload(destination, release.sha256Hex);
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> verifyDownload(File archive, String expected) async {
    final actual = await sha256.bind(archive.openRead()).single;
    if (actual.toString() != expected) {
      throw const UpdateException(
        'The download failed its SHA-256 check. Try downloading it again.',
      );
    }
  }

  static bool isTrustedAssetRedirect(Uri url) =>
      url.scheme == 'https' &&
      _assetHosts.contains(url.host) &&
      url.userInfo.isEmpty &&
      url.port == 443 &&
      _assetPath.hasMatch(url.path) &&
      !url.hasFragment;

  HttpClient _client() => HttpClient()
    ..connectionTimeout = _timeout
    ..autoUncompress = false;

  Future<HttpClientResponse> _get(
    HttpClient client,
    Uri uri, {
    String? accept,
  }) async {
    final request = await client.getUrl(uri).timeout(_timeout);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.userAgentHeader, 'ConsultAgent-Updater');
    if (accept != null) request.headers.set(HttpHeaders.acceptHeader, accept);
    return request.close().timeout(_timeout);
  }
}
