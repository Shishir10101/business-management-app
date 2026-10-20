import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_providers.dart';

/// True while the device has no usable network connection.
///
/// Every "online" observation — the initial one, or a restore after being
/// offline — automatically attempts a sync (queued writes flush, server
/// changes pull in). Override this provider in tests to avoid touching the
/// platform channel.
final isOfflineProvider = StreamProvider<bool>((ref) async* {
  bool? wasOffline;
  await for (final results in Connectivity().onConnectivityChanged) {
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (!offline && (wasOffline == null || wasOffline == true)) {
      refreshSyncFromRef(ref);
    }
    wasOffline = offline;
    yield offline;
  }
});
