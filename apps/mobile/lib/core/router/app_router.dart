import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/onboarding/onboarding_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/backup/presentation/pages/backup_page.dart';
import '../../features/business/presentation/pages/business_list_page.dart';
import '../../features/business/presentation/pages/business_members_page.dart';
import '../../features/business/presentation/pages/business_setup_page.dart';
import '../../features/business/presentation/providers/business_providers.dart';
import '../../features/dashboard/presentation/pages/home_page.dart';
import '../../features/expenses/presentation/pages/expense_form_page.dart';
import '../../features/expenses/presentation/pages/expense_list_page.dart';
import '../../features/income/presentation/pages/income_form_page.dart';
import '../../features/income/presentation/pages/income_list_page.dart';
import '../../features/import/presentation/pages/import_page.dart';
import '../../features/inventory/presentation/pages/inventory_dashboard_page.dart';
import '../../features/inventory/presentation/pages/stock_adjust_page.dart';
import '../../features/inventory/presentation/pages/stock_movements_page.dart';
import '../../features/invoices/presentation/pages/invoice_detail_page.dart';
import '../../features/invoices/presentation/pages/invoice_form_page.dart';
import '../../features/invoices/presentation/pages/invoice_list_page.dart';
import '../../features/notifications/presentation/pages/notification_list_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/parties/domain/entities/party_entity.dart';
import '../../features/parties/presentation/pages/party_form_page.dart';
import '../../features/parties/presentation/pages/party_ledger_page.dart';
import '../../features/parties/presentation/pages/party_list_page.dart';
import '../../features/payments/presentation/pages/payment_form_page.dart';
import '../../features/payments/presentation/pages/payment_list_page.dart';
import '../../features/payments/presentation/pages/payment_methods_page.dart';
import '../../features/products/presentation/pages/category_manage_page.dart';
import '../../features/products/presentation/pages/product_form_page.dart';
import '../../features/products/presentation/pages/product_list_page.dart';
import '../../features/products/presentation/pages/unit_manage_page.dart';
import '../../features/purchases/presentation/pages/purchase_detail_page.dart';
import '../../features/purchases/presentation/pages/purchase_form_page.dart';
import '../../features/purchases/presentation/pages/purchase_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/quotations/presentation/pages/quotation_detail_page.dart';
import '../../features/quotations/presentation/pages/quotation_form_page.dart';
import '../../features/quotations/presentation/pages/quotation_list_page.dart';
import '../../features/reminders/presentation/pages/reminder_form_page.dart';
import '../../features/reminders/presentation/pages/reminder_list_page.dart';
import '../../features/shell/presentation/pages/app_shell.dart';
import '../../features/shell/presentation/pages/more_page.dart';
import '../../features/tools/presentation/pages/calculators_page.dart';
import '../../features/business/presentation/pages/bank_accounts_page.dart';
import '../../features/settings/presentation/pages/app_lock_settings_page.dart';
import '../../features/reports/presentation/pages/expense_report_page.dart';
import '../../features/reports/presentation/pages/income_report_page.dart';
import '../../features/reports/presentation/pages/profit_loss_page.dart';
import '../../features/reports/presentation/pages/receivable_payable_page.dart';
import '../../features/reports/presentation/pages/report_list_page.dart';
import '../../features/reports/presentation/pages/sales_report_page.dart';
import '../../features/reports/presentation/pages/stock_report_page.dart';
import '../../features/sync/presentation/pages/sync_status_page.dart';
import '../../features/sales/presentation/pages/sale_detail_page.dart';
import '../../features/sales/presentation/pages/sale_form_page.dart';
import '../widgets/route_not_found_screen.dart';
import '../../features/sales/presentation/pages/sale_list_page.dart';

/// Paths that own a tab in the bottom bar.
///
/// `openRoute` uses this to decide between replacing the stack (a tab root —
/// the bar is the navigation) and pushing onto it (everything else — the
/// screen you came from must stay one back-tap away). Kept next to the router
/// so the two can never disagree.
const tabRoots = <String>{
  '/',
  '/sales',
  '/customers',
  '/suppliers',
  '/products',
  '/inventory',
  '/more',
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // AuthState is a sealed class, not an AsyncValue: a type test is the
      // idiomatic check (and the only one that compiles).
      final isAuthenticated = authState is AuthAuthenticated;
      final seenWelcome = ref.watch(onboardingSeenProvider);

      final location = state.matchedLocation;
      final atWelcome = location == '/welcome';
      final isAuthRoute = location == '/login' || location == '/register';

      if (!isAuthenticated) {
        // First run: the welcome screen owns the language choice, so it comes
        // before sign-in rather than after it.
        if (!seenWelcome) return atWelcome ? null : '/welcome';
        // Seen it already: skip straight to sign-in and never show it again.
        if (atWelcome) return '/login';
        return isAuthRoute ? null : '/login';
      }

      if (isAuthRoute || atWelcome) {
        return '/';
      }

      // Authenticated users with no business are sent through the setup flow.
      // (Setup is always reachable directly for creating additional businesses.)
      if (location == '/') {
        final businesses = ref.watch(myBusinessesProvider);
        if (!businesses.isLoading && businesses.valueOrNull?.isEmpty == true) {
          return '/business/setup';
        }
      }

      return null;
    },
    routes: [
      // --- The five tabs -------------------------------------------------
      // A shopkeeper works out of four screens all day (home, sales, the
      // khata, the catalogue) and looks for everything else in More. Each
      // branch keeps its own navigator, so switching tabs preserves scroll
      // position and any screen pushed inside that branch.
      //
      // Suppliers and inventory share the parties/items branches rather than
      // taking a sixth tab: they are the same job seen from the other side,
      // and a six-tab bar starts truncating labels in Nepali.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sales',
                builder: (context, state) => const SaleListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const PartyListPage(
                  kind: PartyKind.customer,
                  showKindToggle: true,
                ),
              ),
              GoRoute(
                path: '/suppliers',
                builder: (context, state) => const PartyListPage(
                  kind: PartyKind.supplier,
                  showKindToggle: true,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (context, state) => const ProductListPage(),
              ),
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MorePage(),
              ),
            ],
          ),
        ],
      ),

      // --- Everything else pushes over the shell --------------------------
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/business/setup',
        builder: (context, state) => const BusinessSetupPage(),
      ),
      GoRoute(
        path: '/businesses',
        builder: (context, state) => const BusinessListPage(),
      ),
      GoRoute(
        path: '/businesses/:id/members',
        builder: (context, state) => BusinessMembersPage(
          businessId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/products/new',
        builder: (context, state) => const ProductFormPage(),
      ),
      GoRoute(
        path: '/products/categories',
        builder: (context, state) => const CategoryManagePage(),
      ),
      GoRoute(
        path: '/products/units',
        builder: (context, state) => const UnitManagePage(),
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (context, state) => ProductFormPage(
          productId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/inventory/:productId/adjust',
        builder: (context, state) => StockAdjustPage(
          productId: int.parse(state.pathParameters['productId']!),
        ),
      ),
      GoRoute(
        path: '/inventory/:productId/movements',
        builder: (context, state) => StockMovementsPage(
          productId: int.parse(state.pathParameters['productId']!),
        ),
      ),
      // --- Customers ---
      GoRoute(
        path: '/customers/new',
        builder: (context, state) =>
            const PartyFormPage(kind: PartyKind.customer),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        builder: (context, state) => PartyFormPage(
          kind: PartyKind.customer,
          partyId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/customers/:id/ledger',
        builder: (context, state) => PartyLedgerPage(
          kind: PartyKind.customer,
          partyId: int.parse(state.pathParameters['id']!),
        ),
      ),
      // --- Suppliers ---
      GoRoute(
        path: '/suppliers/new',
        builder: (context, state) =>
            const PartyFormPage(kind: PartyKind.supplier),
      ),
      GoRoute(
        path: '/suppliers/:id/edit',
        builder: (context, state) => PartyFormPage(
          kind: PartyKind.supplier,
          partyId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/suppliers/:id/ledger',
        builder: (context, state) => PartyLedgerPage(
          kind: PartyKind.supplier,
          partyId: int.parse(state.pathParameters['id']!),
        ),
      ),
      // --- Sales ---
      GoRoute(
        path: '/sales/new',
        builder: (context, state) => const SaleFormPage(),
      ),
      GoRoute(
        path: '/sales/:id',
        builder: (context, state) => SaleDetailPage(
          saleId: int.parse(state.pathParameters['id']!),
        ),
      ),
      // --- Purchases ---
      GoRoute(
        path: '/purchases',
        builder: (context, state) => const PurchaseListPage(),
      ),
      GoRoute(
        path: '/purchases/new',
        builder: (context, state) => const PurchaseFormPage(),
      ),
      GoRoute(
        path: '/purchases/:id',
        builder: (context, state) => PurchaseDetailPage(
          purchaseId: int.parse(state.pathParameters['id']!),
        ),
      ),
      // --- Expenses ---
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpenseListPage(),
      ),
      GoRoute(
        path: '/expenses/new',
        builder: (context, state) => const ExpenseFormPage(),
      ),
      GoRoute(
        path: '/expenses/:id/edit',
        builder: (context, state) => ExpenseFormPage(
          expenseId: int.parse(state.pathParameters['id']!),
        ),
      ),
      // --- Income ---
      GoRoute(
        path: '/income',
        builder: (context, state) => const IncomeListPage(),
      ),
      GoRoute(
        path: '/income/new',
        builder: (context, state) => const IncomeFormPage(),
      ),
      GoRoute(
        path: '/income/:id/edit',
        builder: (context, state) => IncomeFormPage(
          incomeId: int.parse(state.pathParameters['id']!),
        ),
      ),
      // --- Payments ---
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentListPage(),
      ),
      GoRoute(
        path: '/payments/new',
        builder: (context, state) => const PaymentFormPage(),
      ),
      GoRoute(
        path: '/payments/methods',
        builder: (context, state) => const PaymentMethodsPage(),
      ),
      // --- Invoices ---
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoiceListPage(),
      ),
      GoRoute(
        path: '/invoices/new',
        builder: (context, state) => const InvoiceFormPage(),
      ),
      GoRoute(
        path: '/invoices/:id',
        builder: (context, state) => InvoiceDetailPage(
          invoiceId: int.parse(state.pathParameters['id']!),
        ),
      ),
      // --- Quotations ---
      GoRoute(
        path: '/quotations',
        builder: (context, state) => const QuotationListPage(),
      ),
      GoRoute(
        path: '/quotations/new',
        builder: (context, state) => const QuotationFormPage(),
      ),
      GoRoute(
        path: '/quotations/:id',
        builder: (context, state) => QuotationDetailPage(
          quotationId: int.parse(state.pathParameters['id']!),
        ),
      ),
      // --- Reports ---
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportListPage(),
      ),
      GoRoute(
        path: '/reports/sales',
        builder: (context, state) => const SalesReportPage(),
      ),
      GoRoute(
        path: '/reports/profit-loss',
        builder: (context, state) => const ProfitLossPage(),
      ),
      GoRoute(
        path: '/reports/expenses',
        builder: (context, state) => const ExpenseReportPage(),
      ),
      GoRoute(
        path: '/reports/income',
        builder: (context, state) => const IncomeReportPage(),
      ),
      GoRoute(
        path: '/reports/stock',
        builder: (context, state) => const StockReportPage(),
      ),
      GoRoute(
        path: '/reports/receivable-payable',
        builder: (context, state) => const ReceivablePayablePage(),
      ),
      // --- Sync ---
      GoRoute(
        path: '/sync',
        builder: (context, state) => const SyncStatusPage(),
      ),
      // --- Notifications ---
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListPage(),
      ),
      GoRoute(
        path: '/notifications/settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      // --- Reminders ---
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const ReminderListPage(),
      ),
      GoRoute(
        path: '/tools/calculators',
        builder: (context, state) => const CalculatorsPage(),
      ),
      GoRoute(
        path: '/settings/app-lock',
        builder: (context, state) => const AppLockSettingsPage(),
      ),
      GoRoute(
        path: '/businesses/bank-accounts',
        builder: (context, state) => const BankAccountsPage(),
      ),
      GoRoute(
        path: '/reminders/new',
        builder: (context, state) => const ReminderFormPage(),
      ),
      GoRoute(
        path: '/reminders/:id/edit',
        builder: (context, state) => ReminderFormPage(
          reminderId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
      // --- Backup ---
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupPage(),
      ),
      // --- CSV import (products, customers) ---
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportPage(),
      ),
    ],
    // Without this, an unmatched location lands on go_router's default error
    // screen: English-only, outside the theme, and it renders the raw exception
    // (an opaque GoException that can carry an internal path). See
    // RouteNotFoundScreen.
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
  );
});
