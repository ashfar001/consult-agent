import 'package:consult_agent/services/launch_detector.dart';
import 'package:consult_agent/services/win32/process_lister.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prompts once for a newly started CAD app, not on startup or repeat polls', () async {
    final processes = FakeProcessLister({'acad.exe'});
    final detector = LaunchDetector(
      lister: processes,
      triggers: {'acad.exe', 'revit.exe'},
      pollInterval: const Duration(seconds: 3),
      isDue: (_) => true,
    );
    var prompts = 0;
    final subscription = detector.promptRequests.listen((_) => prompts++);

    await detector.pollOnce(); // CAD was already open when the agent started.
    await detector.pollOnce();
    processes.names = {'acad.exe', 'chrome.exe'};
    await detector.pollOnce(); // Another app opening is irrelevant.
    expect(prompts, 0);

    processes.names = {'chrome.exe'};
    await detector.pollOnce();
    processes.names = {'chrome.exe', 'acad.exe'};
    await detector.pollOnce();
    await detector.pollOnce();
    expect(prompts, 1);

    await subscription.cancel();
    detector.dispose();
  });
}
