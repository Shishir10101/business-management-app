import 'dart:io';
void main() async {
  try {
    final r = await Process.run('cmd', ['/c', 'ver']);
    print('SPAWN OK: ${r.stdout.toString().trim()}');
  } catch (e) {
    print('SPAWN FAILED: $e');
  }
}
