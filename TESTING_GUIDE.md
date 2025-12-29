# Abort Email Verification - Testing Guide

## Manual Testing Procedures

### Test Case 1: New Signup - Abort Operation
**Prerequisites**: User is not signed in or is signed in anonymously

**Steps**:
1. Open the app and navigate to signup screen
2. Fill in sign-up form with valid credentials:
   - Username: "Test User"
   - Email: "test.abort.signup@example.com"
   - Password: "testPassword123" (minimum 8 chars)
3. Click "Sign Up" button
4. Wait for navigation to verification screen
5. **VERIFY**: Email is displayed on screen
6. Click "Abort Operation" button
7. **VERIFY**: Snackbar shows: "Account creation cancelled. Please sign up again if you wish to create an account."
8. **VERIFY**: Screen navigates back to sign-in/sign-up page (/signin)
9. Try to log in with the email from step 2
10. **EXPECTED**: Login should fail (account was deleted)

**Backend Verification**:
- Firebase Auth: Account should not exist
- Firestore: Users collection should not have this UID document

---

### Test Case 2: Email Update - Abort Operation
**Prerequisites**: User is signed in with a confirmed email

**Steps**:
1. Open the app and navigate to Settings screen
2. User should be signed in with original email (e.g., "original@example.com")
3. In settings, fill in the email update form:
   - New Email: "updated.abort@example.com"
   - Current Password: [enter current password]
4. Click "Update Email" or "Update Credentials" button
5. Wait for navigation to verification screen
6. **VERIFY**: New email is displayed on screen
7. Click "Abort Operation" button
8. **VERIFY**: Snackbar shows: "Email verification cancelled. You can update your email again anytime from settings."
9. **VERIFY**: Screen navigates back to previous screen (app/settings)
10. Check user's email in settings
11. **EXPECTED**: Email should still be the original email

**Backend Verification**:
- Firebase Auth: User's email should remain unchanged
- Firestore: User document should still have original email
- No orphaned verification records

---

### Test Case 3: Email Update - Continue with Verification
**Prerequisites**: User is signed in with confirmed email

**Steps**:
1. Navigate to Settings
2. Click "Update Email"
3. Enter new email and current password
4. Click "Update Email" button
5. Navigate to verification screen
6. **Verify email is the new one** ← Important difference from abort test
7. In real Gmail (or test email), click verification link
8. **VERIFY**: Screen automatically redirects to home
9. Check settings
10. **EXPECTED**: Email should be updated to new email

---

### Test Case 4: Signup - Continue with Verification
**Prerequisites**: Firebase uses a test email service or real Gmail

**Steps**:
1. Sign up with valid credentials and test email
2. Navigate to verification screen
3. In test email inbox, find verification email from Firebase
4. Click the verification link
5. **VERIFY**: Screen automatically redirects to home/profile
6. Check user status
7. **EXPECTED**: User should be fully authenticated (not anonymous)

---

## Unit Test Examples

### Test: AbortEmailVerification for New Signup
```dart
test('abortEmailVerification with isNewSignup=true deletes user', () async {
  final authNotifier = AuthNotifier();
  
  // Setup: Create a test user in anonymous state
  await authNotifier.ensureAuthenticated();
  
  // Call abort with new signup flag
  await authNotifier.abortEmailVerification(isNewSignup: true);
  
  // Verify: User should be anonymous again
  expect(
    authNotifier.getCurrentUser()?.isAnonymous,
    equals(true),
  );
});
```

### Test: AbortEmailVerification for Email Update
```dart
test('abortEmailVerification with isNewSignup=false keeps user signed in', 
  () async {
  final repository = InMemoryAuthRepository();
  
  // Setup: Sign in with email/password
  repository.registerTestUser('user@example.com', 'password123', username: 'Test');
  await repository.signIn('user@example.com', 'password123');
  final beforeUser = repository.getCurrentUser();
  
  // Call abort with email update flag
  await repository.abortEmailVerification(isNewSignup: false);
  
  // Verify: User should still be signed in
  final afterUser = repository.getCurrentUser();
  expect(afterUser?.email, equals(beforeUser?.email));
  expect(afterUser?.isAnonymous, equals(false));
});
```

---

## Widget Test Examples

### Test: Verification Screen Abort Button
```dart
testWidgets('Verification screen shows abort button', 
  (WidgetTester tester) async {
  await tester.pumpWidget(buildTestApp());
  
  // Navigate to verification screen
  await tester.tap(find.byKey(const Key('sign_up_button')));
  await tester.pumpAndSettle();
  
  // Verify abort button exists
  expect(
    find.widgetWithText(OutlinedButton, 'Abort Operation'),
    findsOneWidget,
  );
});
```

### Test: Abort Button Text Changes During Operation
```dart
testWidgets('Abort button shows loading state', 
  (WidgetTester tester) async {
  await tester.pumpWidget(buildTestApp());
  
  // Navigate to verification screen
  await tester.tap(find.byKey(const Key('sign_up_button')));
  await tester.pumpAndSettle();
  
  // Start abort operation
  await tester.tap(find.widgetWithText(OutlinedButton, 'Abort Operation'));
  await tester.pump(); // Frame while loading
  
  // Verify loading text
  expect(
    find.widgetWithText(OutlinedButton, 'Aborting...'),
    findsOneWidget,
  );
});
```

---

## Integration Test Examples

### Test: Complete Signup Abort Flow
```dart
testWidgets('Complete signup abort flow', 
  (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
  
  // Navigate to signup
  await tester.tap(find.text('Sign up instead'));
  await tester.pumpAndSettle();
  
  // Fill signup form
  await tester.enterText(find.byKey(const Key('username_field')), 'Test');
  await tester.enterText(find.byKey(const Key('email_field')), 'test@abort.com');
  await tester.enterText(find.byKey(const Key('password_field')), 'Test1234');
  
  // Submit
  await tester.tap(find.byKey(const Key('sign_up_button')));
  await tester.pumpAndSettle();
  
  // Verify on verification screen
  expect(find.text('test@abort.com'), findsWidgets);
  
  // Click abort
  await tester.tap(find.text('Abort Operation'));
  await tester.pumpAndSettle();
  
  // Verify back on signin screen
  expect(find.text('Sign up for a new account.'), findsOneWidget);
  
  // Verify account was deleted
  await tester.enterText(find.byKey(const Key('email_field_signin')), 'test@abort.com');
  await tester.enterText(find.byKey(const Key('password_field_signin')), 'Test1234');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  
  // Should see error about invalid credentials
  expect(find.text(contains('Error')), findsOneWidget);
});
```

---

## Firebase Emulator Testing

### Setup for Local Testing
```bash
# Start Firebase emulator suite
firebase emulators:start --only auth,firestore

# In your test code, connect to emulator
await Firebase.initializeApp(
  options: FirebaseOptions(
    apiKey: 'test-api-key',
    appId: 'test-app-id',
    messagingSenderId: 'test-sender-id',
    projectId: 'test-project-id',
    authDomain: 'localhost:9099',
  ),
);

// Use emulator for auth
FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

---

## Error Scenarios to Test

### Scenario 1: Network Error During Abort
**Expected**: User sees error snackbar, can retry

```dart
test('abort handles network error gracefully', () async {
  // Mock repository to throw error
  final mockRepository = MockAuthRepository();
  mockRepository.setAbortError('Network error');
  
  // Call abort
  await expectLater(
    authNotifier.abortEmailVerification(isNewSignup: true),
    throwsException,
  );
});
```

### Scenario 2: User Deleted Before Abort
**Expected**: Proper error message

```dart
test('abort handles already-deleted user', () async {
  final repository = FirebaseAuthRepository();
  
  // Delete user
  await repository.signOut(); // Signs out
  
  // Try to abort (no current user)
  await expectLater(
    repository.abortEmailVerification(isNewSignup: true),
    throwsA(isA<Exception>()),
  );
});
```

### Scenario 3: Firestore Write Failure
**Expected**: Firebase cleanup and transaction handling

```dart
test('abort handles firestore deletion failure', () async {
  // Mock Firestore to fail
  final mockFirestore = MockFirebaseFirestore();
  mockFirestore.setDeleteFailure(true);
  
  // Call abort
  await expectLater(
    repository.abortEmailVerification(isNewSignup: true),
    throwsException,
  );
});
```

---

## Verification Checklist

### Code Review Checklist
- [ ] Email verification session is set before navigation
- [ ] Abort method reads session value correctly
- [ ] New signup path deletes both Auth account and Firestore document
- [ ] Email update path leaves user signed in
- [ ] Correct snackbar messages shown
- [ ] Correct navigation after abort
- [ ] No console errors
- [ ] All imports are present
- [ ] No unused imports
- [ ] Code follows app architecture patterns

### Functional Testing Checklist
- [ ] Signup abort works end-to-end
- [ ] Email update abort works end-to-end
- [ ] User cannot log in with deleted account
- [ ] Existing user keeps original email after abort
- [ ] Loading states show correctly
- [ ] Error messages are clear
- [ ] Navigation is smooth
- [ ] Works on multiple devices/screen sizes

### Firebase Verification Checklist
- [ ] Deleted users don't appear in Firebase Auth console
- [ ] User documents are deleted from Firestore
- [ ] No orphaned data in Firestore
- [ ] Email isn't updated if abort is clicked
- [ ] Email verification records are handled correctly

---

## Troubleshooting

### Issue: "No authenticated user" error on abort
**Solution**: Verify user is signed in before aborting. Check that AuthNotifier state is correct.

### Issue: User can still log in after signup abort
**Solution**: Verify both `user.delete()` AND Firestore document deletion are completing. Check Firebase Auth rules.

### Issue: Email isn't being updated after continuing verification
**Solution**: Ensure `verifyBeforeUpdateEmail()` is being called correctly. Check Firebase verification email delivery.

### Issue: User state not updating after abort
**Solution**: Verify `ref.read(authProvider.notifier).state` is being updated. Check Riverpod listener setup.
