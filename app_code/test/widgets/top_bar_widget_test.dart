import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/widgets/top_bar_with_navbar.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/test_providers/test_auth_provider.dart';
import 'package:app_code/repositories/test_repo/in_memory_auth_repository.dart';

void main() {
  late InMemoryAuthRepository authRepository;

  setUp(() async {
    authRepository = InMemoryAuthRepository();
  });

  tearDown(() {
    authRepository.reset();
  });

  Future<ProviderContainer> pumpTopBar(
    WidgetTester tester, {
    required bool isAnonymous,
  }) async {
    if (isAnonymous) {
      await authRepository.signInAnonymously();
    } else {
      await authRepository.signUp('user@example.com', 'password123');
    }

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        authProvider.overrideWith(() => TestAuthNotifier(authRepository)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            appBar: TopBarWithNavBar(),
            body: const SizedBox.shrink(),
          ),
          routes: {
            '/signin': (context) =>
                const Scaffold(body: Text('Sign In Screen')),
            '/settings': (context) =>
                const Scaffold(body: Text('Settings Screen')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('TopBar shows app title', (tester) async {
    await pumpTopBar(tester, isAnonymous: true);

    expect(find.text('My Shopping App'), findsOneWidget);
  });

  testWidgets('TopBar shows supermarket info bar', (tester) async {
    await pumpTopBar(tester, isAnonymous: true);

    expect(
      find.text('Nearest supermarket: internet not available'),
      findsOneWidget,
    );
  });

  testWidgets('TopBar shows Sign In button for anonymous users', (
    tester,
  ) async {
    await pumpTopBar(tester, isAnonymous: true);

    expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('TopBar does not show Sign In button for authenticated users', (
    tester,
  ) async {
    await pumpTopBar(tester, isAnonymous: false);

    expect(find.byKey(const Key('sign_in_button')), findsNothing);
    expect(find.text('Sign In'), findsNothing);
  });

  testWidgets(
    'TopBar shows settings and logout buttons for authenticated users',
    (tester) async {
      await pumpTopBar(tester, isAnonymous: false);

      expect(find.byKey(const Key('settings_button')), findsOneWidget);
      expect(find.byKey(const Key('logout_button')), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    },
  );

  testWidgets('TopBar does not show settings and logout for anonymous users', (
    tester,
  ) async {
    await pumpTopBar(tester, isAnonymous: true);

    expect(find.byKey(const Key('settings_button')), findsNothing);
    expect(find.byKey(const Key('logout_button')), findsNothing);
  });

  testWidgets('Sign In button navigates to signin route', (tester) async {
    await pumpTopBar(tester, isAnonymous: true);

    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    // Verify navigation by checking the route
    expect(find.text('Sign In Screen'), findsOneWidget);
  });

  testWidgets('Settings button navigates to settings route', (tester) async {
    await pumpTopBar(tester, isAnonymous: false);

    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle();

    expect(find.text('Settings Screen'), findsOneWidget);
  });

  testWidgets('Logout button calls signOut', (tester) async {
    await pumpTopBar(tester, isAnonymous: false);

    final userBefore = authRepository.getCurrentUser();
    expect(userBefore!.isAnonymous, isFalse);

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    // After logout, user should be anonymous
    final userAfter = authRepository.getCurrentUser();
    expect(userAfter!.isAnonymous, isTrue);
  });

  testWidgets('TopBar updates when auth state changes', (tester) async {
    // Start with anonymous
    final container = await pumpTopBar(tester, isAnonymous: true);

    expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
    expect(find.byKey(const Key('settings_button')), findsNothing);

    // Sign up to change state
    await container
        .read(authProvider.notifier)
        .signUp('newuser@example.com', 'password123');

    await tester.pumpAndSettle();

    // The ConsumerWidget should rebuild with new auth state
    // After rebuild, settings and logout should be visible
    expect(find.byKey(const Key('settings_button')), findsOneWidget);
    expect(find.byKey(const Key('logout_button')), findsOneWidget);
  });

  testWidgets('TopBar has proper preferred size', (tester) async {
    await pumpTopBar(tester, isAnonymous: true);

    // Create a widget that uses TopBar's preferredSize
    final appBar = TopBarWithNavBar();
    expect(appBar.preferredSize.height, kToolbarHeight + 48);
  });

  testWidgets('TopBar has appropriate spacing', (tester) async {
    await pumpTopBar(tester, isAnonymous: true);

    // Verify both title and info bar are present
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Container), findsWidgets); // Info bar container
  });
}
