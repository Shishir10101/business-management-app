/// A comparable `major.minor.patch` version.
///
/// The app ships as a sideloaded APK, so "is there a newer one?" has to be
/// answered by the app itself — there is no Play Store to do it. That check
/// compares the installed version against the tag of the latest GitHub release,
/// which is why this type exists rather than a plain string compare:
/// `"1.10.0" > "1.9.0"` is true semantically but false lexically.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  /// Accepts `v1.2.3`, `1.2.3`, `1.2.3+7` and `1.2.3-beta.1`.
  ///
  /// The `v` prefix is what git tags look like; the `+7` suffix is Flutter's
  /// build number, which deliberately does not participate in comparison —
  /// two builds of the same semantic version are not an upgrade.
  static final RegExp _pattern = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)');

  static AppVersion? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    final match = _pattern.firstMatch(raw.trim());
    if (match == null) {
      return null;
    }
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) {
      return major.compareTo(other.major);
    }
    if (minor != other.minor) {
      return minor.compareTo(other.minor);
    }
    return patch.compareTo(other.patch);
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;

  bool operator <(AppVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
