import 'package:app_code/models/user.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/screens/settings/settings_screen.dart';
import 'package:app_code/services/database_manager/manage_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
	TestWidgetsFlutterBinding.ensureInitialized();

	Widget buildScreen({required User? user}) {
		return MaterialApp(
			home: SettingsScreen(
				userManager: _FakeUserManager(user),
				authRepository: _FakeAuthRepository(),
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

class _FakeUserManager extends UserManager {
	_FakeUserManager(this.user);

	final User? user;

	@override
	Future<User?> getUserData() async => user;

	@override
	Future<void> setUserData(User user) async {}
}

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
}
