const _browsers = {
  'chrome.exe',
  'msedge.exe',
  'firefox.exe',
  'brave.exe',
  'opera.exe',
  'iexplore.exe',
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
  if (_browsers.contains(exe) &&
      windowTitle.toLowerCase().contains('k-smart')) {
    return 'K-SMART';
  }
  return exe.isEmpty ? 'Other' : 'Other:$exeName';
}
