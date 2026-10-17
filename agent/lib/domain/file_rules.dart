/// Temp, lock and backup files that must never be tracked or uploaded.
bool isIgnoredFile(String path) {
  // Split on both separators so Windows paths work on any host.
  final name = path.split(RegExp(r'[\\/]')).last.toLowerCase();
  if (name.startsWith('~\$')) return true;
  for (final suffix in const ['.bak', r'.sv$', '.dwl', '.dwl2', '.tmp']) {
    if (name.endsWith(suffix)) return true;
  }
  return false;
}
