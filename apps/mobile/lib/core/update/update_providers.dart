import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'update_service.dart';

/// Shared update checker.
///
/// A single instance per app: the dialog and any future "check now" action must
/// agree, and Dio keeps its connection pool per instance.
final updateServiceProvider = Provider<UpdateService>(
  (ref) => UpdateService(
    owner: AppConfig.updateRepoOwner,
    repo: AppConfig.updateRepoName,
  ),
);
