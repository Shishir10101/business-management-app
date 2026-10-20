import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_entity.dart';

/// Snapshot for the home dashboard (today/month totals, trend, top items).
final dashboardProvider = FutureProvider<DashboardEntity>((ref) async {
  return ref.read(dashboardRepositoryProvider).getDashboard();
});

/// Refreshes the dashboard after a mutation that affects its totals.
void refreshDashboard(WidgetRef ref) {
  ref.invalidate(dashboardProvider);
}
