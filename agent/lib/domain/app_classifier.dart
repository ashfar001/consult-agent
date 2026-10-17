/// Browsers tracked by name, so the manager can see when someone is on
/// Chrome. A K-SMART window title still wins (see [classifyApp]).
const _browserNames = {
  'chrome.exe': 'Chrome',
  'msedge.exe': 'Edge',
  'firefox.exe': 'Firefox',
  'brave.exe': 'Brave',
  'opera.exe': 'Opera',
  'iexplore.exe': 'Internet Explorer',
};

/// Executables that raise the project prompt when started.
const cadExecutables = {'acad.exe', 'revit.exe', 'sketchup.exe'};

/// Maps a foreground process + window title to the app name used in reports.
String classifyApp(String exeName, String windowTitle) {
  final exe = exeName.toLowerCase();
  switch (exe) {
    case 'acad.exe':
      return 'AutoCAD';
    case 'revit.exe':
      return 'Revit';
    case 'sketchup.exe':
      return 'SketchUp';
    case 'excel.exe':
      return 'Excel';
  }
  final browser = _browserNames[exe];
  if (browser != null) {
    return windowTitle.toLowerCase().contains('k-smart') ? 'K-SMART' : browser;
  }
  return exe.isEmpty ? 'Other' : 'Other:$exeName';
}
