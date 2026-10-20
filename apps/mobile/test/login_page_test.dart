import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:khata/features/auth/domain/entities/user_entity.dart';
import 'package:khata/features/auth/domain/repositories/auth_repository.dart';
import 'package:khata/features/auth/presentation/pages/login_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// In-memory fake of AuthRepository: records login calls and can simulate errors.
class FakeAuthRepository implements AuthRepository {
  String? lastEmail;
  String? lastPassword;
  Object? loginError;
  bool hasTokensValue = false;

  @override
  Future<bool> hasTokens() async => hasTokensValue;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    if (loginError != null) throw loginError!;
    return const AuthResult(
      user: UserEntity(
        id: 1,
        email: 'test@khata.local',
        fullName: 'Test User',
        locale: 'ne',
        timezone: 'Asia/Kathmandu',
      ),
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresIn: 3600,
    );
  }

  @override
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String locale = 'ne',
  }) async =>
      throw UnimplementedError();

  @override
  Future<AuthResult> refreshToken(String refreshToken) async =>
      throw UnimplementedError();

  @override
  Future<void> logout(String? refreshToken) async {}

  @override
  Future<UserEntity> getProfile() async => throw UnimplementedError();

  @override
  Future<UserEntity> updateProfile({
    required String fullName,
    String? phoneNumber,
    required String locale,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {}

  @override
  Future<void> clearTokens() async {}
}

void main() {
  Future<FakeAuthRepository> pumpLoginPage(
    WidgetTester tester,
    FakeAuthRepository fake,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginPage(),
    ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('shows validation errors for empty fields', (tester) async {
    final fake = await pumpLoginPage(tester, FakeAuthRepository());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    expect(fake.lastEmail, isNull);
  });

  testWidgets('shows validation error for malformed email', (tester) async {
    final fake = await pumpLoginPage(tester, FakeAuthRepository());

    await tester.enterText(
        find.byKey(const Key('login_email')), 'not-an-email');
    await tester.enterText(
        find.byKey(const Key('login_password')), 'Passw0rd123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Please enter a valid email'), findsOneWidget);
    expect(fake.lastEmail, isNull);
  });

  testWidgets('submits credentials to the repository', (tester) async {
    final fake = await pumpLoginPage(tester, FakeAuthRepository());

    await tester.enterText(
        find.byKey(const Key('login_email')), ' test@khata.local ');
    await tester.enterText(
        find.byKey(const Key('login_password')), 'Passw0rd123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(fake.lastEmail, 'test@khata.local');
    expect(fake.lastPassword, 'Passw0rd123');
  });

  testWidgets('shows error snackbar when login fails', (tester) async {
    final fake = FakeAuthRepository()
      ..loginError = Exception('401 unauthorized');
    await pumpLoginPage(tester, fake);

    await tester.enterText(
        find.byKey(const Key('login_email')), 'test@khata.local');
    await tester.enterText(
        find.byKey(const Key('login_password')), 'WrongPassw0rd');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
  });
}
