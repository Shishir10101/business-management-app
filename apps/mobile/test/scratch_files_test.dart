import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khata/core/utils/scratch_files.dart';
import 'package:path/path.dart' as p;

/// The scratch-file writer behind every download-and-share flow: invoice PDF,
/// quotation PDF, report CSV.
///
/// `writeScratchFile` short-circuits to `null` under `kIsWeb`, which a widget
/// test cannot flip — that branch is what the browser walk exercises (it is
/// the fix for the raw `MissingPluginException` users used to see). What is
/// verifiable here is the desktop/phone path: the file lands where it is told
/// to land, with exactly the bytes it was given.
void main() {
  late Directory scratch;

  setUp(() => scratch = Directory.systemTemp.createTempSync('khata_scratch_'));
  tearDown(() {
    try {
      scratch.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('writes the bytes and returns the joined path', () async {
    final path = await writeScratchFile(
      'INV-12.pdf',
      utf8.encode('%PDF-1.7 not-really-a-pdf'),
      directory: () async => scratch,
    );

    expect(path, equals(p.join(scratch.path, 'INV-12.pdf')));
    final file = File(path!);
    expect(file.existsSync(), isTrue);
    expect(utf8.decode(file.readAsBytesSync()), '%PDF-1.7 not-really-a-pdf');
  });

  test('report-style names with dates and dots survive the join', () async {
    final path = await writeScratchFile(
      'sales-report-2026-10-17_2026-10-17.csv',
      [1, 2, 3],
      directory: () async => scratch,
    );

    expect(
      path,
      equals(p.join(scratch.path, 'sales-report-2026-10-17_2026-10-17.csv')),
    );
    expect(File(path!).readAsBytesSync(), [1, 2, 3]);
  });

  test('an overwrite replaces the file rather than appending', () async {
    await writeScratchFile('out.csv', utf8.encode('first'), directory: () async => scratch);
    final path = await writeScratchFile(
      'out.csv',
      utf8.encode('second'),
      directory: () async => scratch,
    );

    expect(utf8.decode(File(path!).readAsBytesSync()), 'second');
  });

  test('a directory that cannot be opened propagates to the caller', () async {
    // The download flows wrap the whole thing in try/catch and show an error
    // snackbar, so a failure here must stay an exception, not become null.
    expect(
      () => writeScratchFile('x.pdf', [0], directory: () async {
        throw const FileSystemException('no such directory');
      }),
      throwsA(isA<FileSystemException>()),
    );
  });
}
