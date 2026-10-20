import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Writes [bytes] to [fileName] in the OS scratch directory and returns the
/// absolute path, so a download/share flow has a real file to hand to
/// `share_plus`.
///
/// Returns **null on the web**, where there is no scratch directory: `dart:io`
/// file access does not exist under wasm and `path_provider` has no web
/// implementation. Callers must treat null as "cannot hand the user a file
/// here" and say so, rather than letting a `MissingPluginException` or
/// `UnsupportedError` surface as a raw English exception string.
///
/// [directory] is injectable so tests can supply a temp folder without the
/// platform channel.
Future<String?> writeScratchFile(
  String fileName,
  List<int> bytes, {
  Future<Directory> Function()? directory,
}) async {
  if (kIsWeb) return null;
  final dir = await (directory ?? getTemporaryDirectory)();
  final path = p.join(dir.path, fileName);
  await File(path).writeAsBytes(bytes);
  return path;
}
