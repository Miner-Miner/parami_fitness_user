import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parami_fitness_user/ui/app_theme.dart';
import 'package:parami_fitness_user/ui/appearance.dart';
import 'package:parami_fitness_user/models/connection_settings.dart';
import 'package:parami_fitness_user/screens/login_screen.dart';
import 'package:parami_fitness_user/services/gym_api.dart';
import 'package:parami_fitness_user/models/gym_models.dart';
import 'package:parami_fitness_user/screens/gym_shell.dart';
import 'package:parami_fitness_user/screens/profile_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('appearance restores independently of account data', () async {
    final controller = AppearanceController();
    await controller.select(theme: MemberTheme.roseGold, dark: true);
    final restored = AppearanceController();
    await restored.restore();
    expect(restored.theme, MemberTheme.roseGold);
    expect(restored.dark, isTrue);
    controller.dispose();
    restored.dispose();
  });

  testWidgets('navigation variants preserve page state and expiry callback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final appearance = AppearanceController();
    addTearDown(appearance.dispose);
    final api = _FakeApi();
    const session = AuthSession(
      sessionId: 'session',
      userId: 46,
      name: 'Member',
      login: 'member@example.com',
      userRole: 'customer',
      memberId: 'MEM-25',
      partnerId: 12,
      isGymAdmin: false,
    );
    await tester.pumpWidget(
      AppearanceScope(
        controller: appearance,
        child: AnimatedBuilder(
          animation: appearance,
          builder: (context, _) => MaterialApp(
            theme: gymTheme(theme: appearance.theme, dark: appearance.dark),
            home: GymShell(api: api, session: session, onLogout: () async {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.reminders, 1);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(ProfileScreen));
    for (final theme in MemberTheme.values) {
      for (final dark in [false, true]) {
        await appearance.select(theme: theme, dark: dark);
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(ProfileScreen)), same(state));
        expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 3);
        expect(
          find.byType(NavigationBar),
          theme == MemberTheme.monochrome ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(NavigationRail),
          theme == MemberTheme.gold ? findsOneWidget : findsNothing,
        );
        expect(api.reminders, 1);
        expect(tester.takeException(), isNull);
      }
    }
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Home'));
    await tester.pumpAndSettle();
    expect(api.reminders, 2);
  });

  testWidgets('all themes and modes preserve login input', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppearanceController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      AppearanceScope(
        controller: controller,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => MaterialApp(
            theme: gymTheme(theme: controller.theme, dark: controller.dark),
            home: LoginScreen(
              api: GymApi(),
              connectionSettings: ConnectionSettings.defaults(),
              onConnectionSettingsChanged: (_) async {},
              onLoggedIn: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'member@example.com',
    );
    for (final theme in MemberTheme.values) {
      await tester.ensureVisible(find.text('Theme'));
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(theme.label));
      await tester.pumpAndSettle();
      expect(controller.theme, theme);
      for (final dark in [true, false]) {
        await tester.tap(
          find.byTooltip(dark ? 'Switch to dark mode' : 'Switch to light mode'),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(TextFormField).first);
        expect(
          Theme.of(context).brightness,
          dark ? Brightness.dark : Brightness.light,
        );
        expect(find.text('member@example.com'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}

class _FakeApi extends GymApi {
  int reminders = 0;
  @override
  Future<PackageRecord?> nearestExpiry(AuthSession session) async {
    reminders++;
    return null;
  }

  @override
  Future<List<FitnessClass>> freeClasses(AuthSession session) async => [];
  @override
  Future<MemberProfile> profile(AuthSession session) async =>
      MemberProfile.fromJson({'name': 'Member', 'login': 'member@example.com'});
  @override
  Future<LoyaltyPoints?> loyaltyPoints(AuthSession session) async => null;
}
