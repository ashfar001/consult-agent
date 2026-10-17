import 'dart:io';

import 'package:consult_agent/data/api/mock_api_client.dart';
import 'package:consult_agent/services/file_watcher.dart';
import 'package:consult_agent/services/folder_manager.dart';
import 'package:consult_agent/services/uploader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'harness.dart';

void main() {
  late Directory tmp;
  late Harness h;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('ca_files');
    h = Harness(DateTime(2026, 10, 5, 9));
    h.api.token = 'mock-token-emp001';
  });

  tearDown(() async {
    await h.dispose();
    tmp.deleteSync(recursive: true);
  });

  FolderManager folders() => FolderManager(
    config: h.config.mergeJson({'projects_root': p.join(tmp.path, 'Projects')}),
    db: h.db,
    api: h.api,
    currentWorkerName: 'Arun Kumar',
  );

  test('sanitizeName strips characters Windows rejects', () {
    expect(sanitizeName('Villa: "North" / Block?'), 'Villa North Block');
    expect(sanitizeName('  ...  '), 'Project');
  });

  test('sync creates the template and downloads files', () async {
    final project = (await h.api.myProjects()).first; // KP-101
    final result = await folders().sync(project);

    expect(p.basename(result.folder), startsWith('KP-101_'));
    for (final d
        in defaultTemplate.isEmpty ? <String>[] : project.folderTemplate) {
      expect(
        Directory(p.join(result.folder, d)).existsSync(),
        isTrue,
        reason: d,
      );
    }
    expect(
      File(p.join(result.folder, '02_Drawings/GF_Plan.dwg')).existsSync(),
      isTrue,
    );
    expect(result.downloaded, 3);
    expect(result.failed, isEmpty);
    // No half-written temp files left behind.
    final leftovers = Directory(
      result.folder,
    ).listSync(recursive: true).where((e) => e.path.endsWith('.part'));
    expect(leftovers, isEmpty);
    expect((await h.db.fileDao.forProject(project.id)), hasLength(3));
  });

  test('a second sync only fetches newer versions', () async {
    final project = (await h.api.myProjects()).first;
    final fm = folders();
    await fm.sync(project);

    expect((await fm.sync(project)).downloaded, 0);

    // Someone uploads a new version of GF_Plan.dwg.
    final t = await h.api.requestUploadUrl(
      clientId: 'x',
      projectId: project.id,
      path: '02_Drawings/GF_Plan.dwg',
      size: 10,
    );
    await h.api.confirmUpload(uploadId: t.uploadId, note: '');
    final again = await fm.sync(project);
    expect(again.downloaded, 1);
  });

  test('files held by another worker are reported read-only', () async {
    final project = (await h.api.myProjects())[1]; // KP-102, Meera holds one
    final result = await folders().sync(project);
    expect(result.readOnly.values, contains('Meera'));
    expect(result.readOnly.keys.single, endsWith('Column_Layout.dwg'));
  });

  test('offline sync opens the local folder without failing', () async {
    final project = (await h.api.myProjects()).first;
    h.api.offline = true;
    final result = await folders().sync(project);
    expect(result.offline, isTrue);
    expect(Directory(result.folder).existsSync(), isTrue);
  });

  test('watcher lists new and edited files, ignoring temp files', () async {
    final project = (await h.api.myProjects()).first;
    final fm = folders();
    final folder = (await fm.sync(project)).folder;

    final watcher = FileWatcher(db: h.db);
    addTearDown(watcher.dispose);
    await watcher.start(project.id, folder);
    expect(watcher.changedFiles, isEmpty);

    File(p.join(folder, '02_Drawings', 'new.dwg')).writeAsStringSync('x');
    File(p.join(folder, '02_Drawings', 'new.dwg.bak')).writeAsStringSync('x');
    File(p.join(folder, '02_Drawings', '~\$lock.xlsx')).writeAsStringSync('x');
    final edited = File(p.join(folder, '02_Drawings', 'GF_Plan.dwg'))
      ..writeAsStringSync('edited');
    edited.setLastModifiedSync(DateTime.now().add(const Duration(minutes: 1)));

    // A restart rebuilds the same list from disk.
    final restarted = FileWatcher(db: h.db);
    addTearDown(restarted.dispose);
    await restarted.start(project.id, folder);
    expect(
      restarted.changedFiles.map(p.basename),
      unorderedEquals(['new.dwg', 'GF_Plan.dwg']),
    );
    expect(restarted.relative(edited.path), '02_Drawings/GF_Plan.dwg');
  });

  group('Uploader', () {
    Uploader make({int max = 1024 * 1024}) =>
        Uploader(db: h.db, api: h.api, clock: () => h.now, maxFileBytes: max);

    test('uploads a file and records the new version', () async {
      final f = File(p.join(tmp.path, 'a.dwg'))..writeAsStringSync('data');
      final up = make();
      addTearDown(up.dispose);
      final q = await up.enqueue(
        projectId: 'p-101',
        files: [
          UploadRequest(localPath: f.path, remotePath: '02_Drawings/a.dwg'),
        ],
        note: 'n',
      );
      expect(q.queued, ['02_Drawings/a.dwg']);
      expect(await up.processQueue(), 1);

      final row = await h.db.uploadDao.byClientId(q.clientIds.single);
      expect(row!.state, 'confirmed');
      expect(row.resultFileId, isNotNull);
      expect(
        (await h.api.projectFiles('p-101')).map((f) => f.path),
        contains('02_Drawings/a.dwg'),
      );
    });

    test('files over the size cap are skipped, not queued', () async {
      final f = File(p.join(tmp.path, 'big.dwg'))
        ..writeAsBytesSync(List.filled(2000, 1));
      final up = make(max: 1000);
      addTearDown(up.dispose);
      final q = await up.enqueue(
        projectId: 'p-101',
        files: [UploadRequest(localPath: f.path, remotePath: 'big.dwg')],
      );
      expect(q.queued, isEmpty);
      expect(q.tooLarge, ['big.dwg']);
    });

    test('offline uploads stay queued and finish later', () async {
      final f = File(p.join(tmp.path, 'a.dwg'))..writeAsStringSync('data');
      final up = make();
      addTearDown(up.dispose);
      final q = await up.enqueue(
        projectId: 'p-101',
        files: [UploadRequest(localPath: f.path, remotePath: 'a.dwg')],
      );
      h.api.offline = true;
      expect(await up.processQueue(), 0);
      expect((await h.db.uploadDao.pending()), hasLength(1));

      h.api.offline = false;
      expect(await up.processQueue(), 1);
      final row = await h.db.uploadDao.byClientId(q.clientIds.single);
      expect(row!.state, 'confirmed');
    });

    test('mark task complete queues the completion', () async {
      final f = File(p.join(tmp.path, 'a.dwg'))..writeAsStringSync('data');
      final up = make();
      addTearDown(up.dispose);
      await up.enqueue(
        projectId: 'p-101',
        files: [UploadRequest(localPath: f.path, remotePath: 'a.dwg')],
        taskId: 't-1011',
        completeTask: true,
      );
      await up.processQueue();
      final rows = await h.db.outboxDao.due(h.now);
      expect(rows.map((r) => r.kind), contains('task_complete'));
    });
  });

  test('MockApiClient dummy content is deterministic', () {
    expect(
      MockApiClient.dummyContent('mock://x', 50),
      MockApiClient.dummyContent('mock://x', 50),
    );
  });
}
