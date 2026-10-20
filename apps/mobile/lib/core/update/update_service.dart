import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import 'app_version.dart';

/// A newer release the user could install.
class UpdateInfo {
  const UpdateInfo({
    required this.current,
    required this.latest,
    required this.downloadUrl,
    required this.releaseUrl,
    required this.notes,
    this.sizeBytes,
    this.publishedAt,
  });

  /// What is installed on this phone.
  final AppVersion current;

  /// What the newest GitHub release offers.
  final AppVersion latest;

  /// Direct link to the `.apk` asset.
  final String downloadUrl;

  /// Human-facing release page, for "what changed" context.
  final String releaseUrl;

  /// Release body written when the tag was published.
  final String notes;

  final int? sizeBytes;
  final DateTime? publishedAt;

  /// "12.4 MB" when the asset size is known, otherwise null.
  String? get sizeLabel {
    final bytes = sizeBytes;
    if (bytes == null || bytes <= 0) {
      return null;
    }
    final mb = bytes / (1024 * 1024);
    return mb >= 1 ? '${mb.toStringAsFixed(1)} MB' : '${(bytes / 1024).round()} KB';
  }
}

/// Asks GitHub whether a newer build exists.
///
/// Reads the *latest release* rather than a hand-maintained version file, so
/// publishing a release is the only step needed to ship an update: the tag
/// supplies the version, the body supplies the release notes, and the `.apk`
/// asset supplies the download. Nothing else to keep in sync.
class UpdateService {
  UpdateService({
    Dio? dio,
    String? owner,
    String? repo,
    Future<PackageInfo> Function()? packageInfoLoader,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ),
        _owner = owner ?? AppConfig.updateRepoOwner,
        _repo = repo ?? AppConfig.updateRepoName,
        _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  final Dio _dio;
  final String _owner;
  final String _repo;
  final Future<PackageInfo> Function() _packageInfoLoader;

  /// The version installed on this device, as declared by the APK manifest.
  ///
  /// Read from the platform rather than from a compile-time constant so it can
  /// never drift from `pubspec.yaml` — a stale constant would either nag about
  /// an update that is already installed or hide a real one.
  Future<AppVersion?> installedVersion() async {
    try {
      final info = await _packageInfoLoader();
      return AppVersion.tryParse(info.version);
    } catch (_) {
      return null;
    }
  }

  /// Returns null when there is nothing to do — which is the common case, and
  /// also what every failure looks like. An update check must never surface an
  /// error: this app is used offline as a matter of course, and a shopkeeper
  /// has no use for "could not reach GitHub".
  Future<UpdateInfo?> check() async {
    final current = await installedVersion();
    if (current == null) {
      return null;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
        options: Options(
          headers: const {
            'Accept': 'application/vnd.github+json',
            // Pin the API version so a future default does not change the
            // shape of the response under us.
            'X-GitHub-Api-Version': '2022-11-28',
          },
        ),
      );

      final data = response.data;
      if (data == null) {
        return null;
      }

      final latest = AppVersion.tryParse(data['tag_name'] as String?);
      if (latest == null || latest.compareTo(current) <= 0) {
        return null;
      }

      final apk = _firstApkAsset(data['assets']);
      if (apk == null) {
        // A release without an APK is a release nobody can install; treat it as
        // "no update" rather than offering a dead button.
        return null;
      }

      return UpdateInfo(
        current: current,
        latest: latest,
        downloadUrl: apk.url,
        releaseUrl: data['html_url'] as String? ?? apk.url,
        notes: (data['body'] as String? ?? '').trim(),
        sizeBytes: apk.size,
        publishedAt: DateTime.tryParse(data['published_at'] as String? ?? ''),
      );
    } catch (_) {
      // Offline, rate-limited (60 req/hour unauthenticated), DNS failure,
      // malformed JSON — all mean the same thing to the user: nothing to do.
      return null;
    }
  }

  ({String url, int? size})? _firstApkAsset(Object? assets) {
    if (assets is! List) {
      return null;
    }
    for (final asset in assets) {
      if (asset is! Map) {
        continue;
      }
      final name = asset['name'];
      final url = asset['browser_download_url'];
      if (name is String &&
          name.toLowerCase().endsWith('.apk') &&
          url is String &&
          url.isNotEmpty) {
        final size = asset['size'];
        return (url: url, size: size is int ? size : null);
      }
    }
    return null;
  }
}
