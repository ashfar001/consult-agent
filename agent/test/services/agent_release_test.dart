import 'package:flutter_test/flutter_test.dart';
import 'package:consult_agent/services/agent_release.dart';

void main() {
  Map<String, Object> release({String? digest, String? url, String? tag}) {
    const asset = 'ConsultAgent-Windows-v1.0.7.zip';
    return {
      'draft': false,
      'prerelease': false,
      'tag_name': tag ?? 'v1.0.7',
      'assets': [
        {
          'name': asset,
          'state': 'uploaded',
          'size': 1024,
          'digest': digest ?? 'sha256:${'a' * 64}',
          'browser_download_url':
              url ??
              'https://github.com/ashfar001/consult-agent/releases/download/v1.0.7/$asset',
        },
      ],
    };
  }

  test('accepts only a newer release with exact asset and digest', () {
    final newer = AgentRelease.fromJson(release(), const AgentVersion(1, 0, 6));
    expect(newer?.version.toString(), '1.0.7');
    expect(newer?.sha256Hex, 'a' * 64);
    expect(
      AgentRelease.fromJson(release(), const AgentVersion(1, 0, 7)),
      isNull,
    );
  });

  test('rejects missing digest and noncanonical download URL', () {
    expect(
      () => AgentRelease.fromJson(
        release(digest: ''),
        const AgentVersion(1, 0, 6),
      ),
      throwsA(isA<UpdateException>()),
    );
    expect(
      () => AgentRelease.fromJson(
        release(url: 'https://example.com/agent.zip'),
        const AgentVersion(1, 0, 6),
      ),
      throwsA(isA<UpdateException>()),
    );
  });
}
