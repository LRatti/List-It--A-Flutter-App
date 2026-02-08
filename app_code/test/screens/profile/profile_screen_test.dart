import 'package:app_code/models/user.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/auth/user_details_provider.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/screens/profile/profile_screen.dart';
import 'package:app_code/repositories/real_app_repo/database_manager_repository/manage_user.dart';
import 'package:app_code/services/database/firebase/manage_user.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAuthNotifier extends AuthNotifier {
	_FakeAuthNotifier(this.user, this.repository);
	final User user;
	final AuthRepository repository;

	@override
	Future<User?> build() async {
		// Don't call super.build() as it tries to access Firebase
		// Just return our test user
		return user;
	}

	@override
	bool canUpdateCredentials() => repository.canUpdateCredentials();
}

void main() {
	TestWidgetsFlutterBinding.ensureInitialized();

	Widget buildScreen({required User? user}) {
		final repo = _FakeAuthRepository();
		return ProviderScope(
			overrides: [
				authRepositoryProvider.overrideWithValue(repo),
				userManagerProvider.overrideWithValue(_FakeUserManager(user)),
				// Provide auth state so userDetailsProvider can work
				if (user != null)
					authProvider.overrideWith(() => _FakeAuthNotifier(user, repo)),
			],
			child: MaterialApp(
				localizationsDelegates: AppLocalizations.localizationsDelegates,
				supportedLocales: AppLocalizations.supportedLocales,
				locale: const Locale('en'),
				home: const ProfileScreen(),
			),
		);
	}

	Finder currentEmailText() {
		return find.byWidgetPredicate((widget) => widget is Text && widget.data == 'Current Email');
	}

	testWidgets('shows current email when available', (tester) async {
		final user = User(email: 'user@example.com', userName: 'Tester');

		await tester.pumpWidget(buildScreen(user: user));
		await tester.pumpAndSettle();

		// Verify the current email label exists and the email text is shown
		expect(currentEmailText(), findsOneWidget);
		expect(find.text('user@example.com'), findsWidgets);
	});

	testWidgets('shows empty email when not provided', (tester) async {
		final user = User(userName: 'NoMail');

		await tester.pumpWidget(buildScreen(user: user));
		await tester.pumpAndSettle();

		// Current email section exists, but no non-empty email text is displayed
		expect(currentEmailText(), findsOneWidget);
		expect(
			find.byWidgetPredicate(
				(w) => w is Text && (w.data?.contains('@') ?? false),
			),
			findsNothing,
		);
	});
}

class _FakeUserManager extends UserDatabaseManager {
	_FakeUserManager(this.user) : super(
		firebaseManager: _MockFirebaseUserManager(),
		firebaseAuth: _MockFirebaseAuth(),
	);

	final User? user;

	@override
	Future<User?> getUserData() async => user;

	@override
	Future<void> setUserData(User user) async {}
}

class _MockFirebaseUserManager extends Mock implements FirebaseUserManager {}

class _MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class _FakeAuthRepository implements AuthRepository {
	@override
	bool canUpdateCredentials() => true;

	@override
	Future<User?> ensureAuthenticated() async => null;

	@override
	User? getCurrentUser() => null;

	@override
	Future<User?> linkAnonymousWithEmailPassword(String email, String password, String username) async {
		return null;
	}

	@override
	Future<void> signOut() async {}

	@override
	Future<User?> signIn(String email, String password) async => null;

	@override
	Future<User?> signInAnonymously() async => null;

	@override
	Future<User?> signInWithGoogle() async => null;

	@override
	Future<User?> signUp(String email, String password) async => null;

	@override
	Future<void> updateEmail({required String newEmail, required String currentPassword}) async {}

	@override
	Future<void> updatePassword({required String newPassword, required String currentPassword}) async {}

	@override
	Future<void> abortEmailVerification({required bool isNewSignup}) async {}

	@override
	Future<void> sendPasswordResetEmail(String email) async {}
}
