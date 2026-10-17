import 'package:consult_agent/domain/admin_gate.dart';
import 'package:consult_agent/services/win32/hotkey_watcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var now = DateTime(2026, 10, 5, 9);
  AdminGate gate({String? password, String? demo}) {
    const salt = 'abc123';
    return AdminGate(
      hash: password == null ? '' : AdminGate.hashPassword(salt, password),
      salt: salt,
      clock: () => now,
      demoPassword: demo,
    );
  }

  setUp(() => now = DateTime(2026, 10, 5, 9));

  test('hash depends on salt and password and is stable', () {
    final a = AdminGate.hashPassword('s1', 'secret-pass');
    expect(a, AdminGate.hashPassword('s1', 'secret-pass'));
    expect(a, isNot(AdminGate.hashPassword('s2', 'secret-pass')));
    expect(a, isNot(AdminGate.hashPassword('s1', 'secret-pasS')));
    expect(a, hasLength(64));
  });

  test('correct password passes, wrong one fails', () {
    final g = gate(password: 'Sup3r-Admin!');
    expect(g.verify('nope'), AdminResult.wrong);
    expect(g.verify('Sup3r-Admin!'), AdminResult.ok);
  });

  test('no password configured means no exit', () {
    final g = gate();
    expect(g.isConfigured, isFalse);
    expect(g.verify('anything'), AdminResult.notConfigured);
    expect(g.verify(''), AdminResult.notConfigured);
  });

  test('three wrong tries lock for 30 s, then it works again', () {
    final g = gate(password: 'Sup3r-Admin!');
    expect(g.verify('a'), AdminResult.wrong);
    expect(g.verify('b'), AdminResult.wrong);
    expect(g.verify('c'), AdminResult.wrong);
    expect(g.lockedSecs, greaterThan(0));

    // Even the right password is refused while locked.
    expect(g.verify('Sup3r-Admin!'), AdminResult.locked);

    now = now.add(const Duration(seconds: 31));
    expect(g.lockedSecs, 0);
    expect(g.verify('Sup3r-Admin!'), AdminResult.ok);
  });

  test('a success resets the failure count', () {
    final g = gate(password: 'Sup3r-Admin!');
    g.verify('a');
    g.verify('b');
    expect(g.verify('Sup3r-Admin!'), AdminResult.ok);
    g.verify('a');
    g.verify('b');
    expect(g.verify('c'), AdminResult.wrong);
    expect(g.lockedSecs, greaterThan(0));
  });

  test('demo password only works when no hash is configured', () {
    expect(gate(demo: 'admin1234').verify('admin1234'), AdminResult.ok);
    expect(gate(demo: 'admin1234').verify('x'), AdminResult.wrong);
    final real = gate(password: 'Sup3r-Admin!', demo: 'admin1234');
    expect(real.verify('admin1234'), AdminResult.wrong);
  });

  test('hotkey fires once per press, not while held', () {
    var down = false;
    final w = HotkeyWatcher(isPressed: () => down);
    var fired = 0;
    w.pressed.listen((_) => fired++);

    w.check();
    down = true;
    w.check();
    w.check();
    w.check();
    down = false;
    w.check();
    down = true;
    w.check();

    return Future<void>.delayed(Duration.zero).then((_) {
      expect(fired, 2);
      w.dispose();
    });
  });
}
