import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:app_code/models/user.dart';
import 'package:app_code/services/database/firebase/manage_user.dart';
import 'package:app_code/repositories/real_app_repo/database_manager_repository/manage_user.dart';

/// Mock classes for dependencies
class MockFirebaseUserManager extends Mock implements FirebaseUserManager {}

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockFirebaseUser extends Mock implements firebase_auth.User {}

void main() {
  late UserDatabaseManager userDatabaseManager;
  late MockFirebaseUserManager mockFirebaseUserManager;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseUser mockFirebaseUser;

  setUp(() {
    mockFirebaseUserManager = MockFirebaseUserManager();
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseUser = MockFirebaseUser();
    
    // Create UserDatabaseManager with injected mocks
    userDatabaseManager = UserDatabaseManager(
      firebaseManager: mockFirebaseUserManager,
      firebaseAuth: mockFirebaseAuth,
    );
  });

  group('UserDatabaseManager', () {
    group('getUserData', () {
      test('returns user data when current user exists and has data in Firebase',
          () async {
        // Arrange
        const testUid = 'test-uid-123';
        final testUser = User(
          uid: testUid,
          email: 'test@example.com',
          userName: 'testuser',
        );

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn(testUid);
        when(() => mockFirebaseUserManager.getUserById(testUid))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await userDatabaseManager.getUserData();

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, testUid);
        expect(result?.email, 'test@example.com');
        verify(() => mockFirebaseAuth.currentUser).called(1);
        verify(() => mockFirebaseUserManager.getUserById(testUid)).called(1);
      });

      test('returns null when current user exists but has no data in Firebase',
          () async {
        // Arrange
        const testUid = 'test-uid-456';

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn(testUid);
        when(() => mockFirebaseUserManager.getUserById(testUid))
            .thenAnswer((_) async => null);

        // Act
        final result = await userDatabaseManager.getUserData();

        // Assert
        expect(result, isNull);
        verify(() => mockFirebaseAuth.currentUser).called(1);
        verify(() => mockFirebaseUserManager.getUserById(testUid)).called(1);
      });

      test('returns null when no user is currently logged in', () async {
        // Arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = await userDatabaseManager.getUserData();

        // Assert
        expect(result, isNull);
        verify(() => mockFirebaseAuth.currentUser).called(1);
        verifyNever(
          () => mockFirebaseUserManager.getUserById(any()),
        );
      });

      test('propagates exception when Firebase throws during data retrieval',
          () async {
        // Arrange
        const testUid = 'test-uid-789';
        final exception = Exception('Firebase connection error');

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn(testUid);
        when(() => mockFirebaseUserManager.getUserById(testUid))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => userDatabaseManager.getUserData(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('setUserData', () {
      test('successfully sets user data in Firebase', () async {
        // Arrange
        final testUser = User(
          uid: 'user-123',
          email: 'user@example.com',
          userName: 'johndoe',
        );

        when(() => mockFirebaseUserManager.setUser(testUser))
            .thenAnswer((_) async {});

        // Act
        await userDatabaseManager.setUserData(testUser);

        // Assert
        verify(() => mockFirebaseUserManager.setUser(testUser)).called(1);
      });

      test('successfully sets user data with minimal fields', () async {
        // Arrange
        final testUser = User(
          uid: 'user-456',
          email: 'minimal@example.com',
        );

        when(() => mockFirebaseUserManager.setUser(testUser))
            .thenAnswer((_) async {});

        // Act
        await userDatabaseManager.setUserData(testUser);

        // Assert
        verify(() => mockFirebaseUserManager.setUser(testUser)).called(1);
      });

      test('successfully sets anonymous user data', () async {
        // Arrange
        final testUser = User(
          uid: 'anon-user-123',
          isAnonymous: true,
        );

        when(() => mockFirebaseUserManager.setUser(testUser))
            .thenAnswer((_) async {});

        // Act
        await userDatabaseManager.setUserData(testUser);

        // Assert
        verify(() => mockFirebaseUserManager.setUser(testUser)).called(1);
      });

      test('propagates exception when Firebase throws during set operation',
          () async {
        // Arrange
        final testUser = User(
          uid: 'user-error-123',
          email: 'error@example.com',
        );
        final exception = Exception('Firebase write failed');

        when(() => mockFirebaseUserManager.setUser(testUser))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => userDatabaseManager.setUserData(testUser),
          throwsA(isA<Exception>()),
        );
      });

      test('propagates exception with network timeout', () async {
        // Arrange
        final testUser = User(
          uid: 'user-timeout-123',
          email: 'timeout@example.com',
        );
        final exception = Exception('Network timeout');

        when(() => mockFirebaseUserManager.setUser(testUser))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => userDatabaseManager.setUserData(testUser),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getUserById', () {
      test('returns user when user exists in Firebase', () async {
        // Arrange
        const testUid = 'user-id-123';
        final expectedUser = User(
          uid: testUid,
          email: 'existing@example.com',
          userName: 'existinguser',
        );

        when(() => mockFirebaseUserManager.getUserById(testUid))
            .thenAnswer((_) async => expectedUser);

        // Act
        final result = await userDatabaseManager.getUserById(testUid);

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, testUid);
        expect(result?.email, 'existing@example.com');
        verify(() => mockFirebaseUserManager.getUserById(testUid)).called(1);
      });

      test('returns null when user does not exist in Firebase', () async {
        // Arrange
        const testUid = 'nonexistent-user-id';

        when(() => mockFirebaseUserManager.getUserById(testUid))
            .thenAnswer((_) async => null);

        // Act
        final result = await userDatabaseManager.getUserById(testUid);

        // Assert
        expect(result, isNull);
        verify(() => mockFirebaseUserManager.getUserById(testUid)).called(1);
      });

      test('returns user with partial data when document exists', () async {
        // Arrange
        const testUid = 'partial-user-id';
        final partialUser = User(
          uid: testUid,
          email: 'partial@example.com',
        );

        when(() => mockFirebaseUserManager.getUserById(testUid))
            .thenAnswer((_) async => partialUser);

        // Act
        final result = await userDatabaseManager.getUserById(testUid);

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, testUid);
        expect(result?.email, 'partial@example.com');
        expect(result?.getUserName(), isEmpty);
      });

      test('propagates exception when Firebase throws during retrieval',
          () async {
        // Arrange
        const testUid = 'error-user-id';
        final exception = Exception('Firestore access denied');

        when(() => mockFirebaseUserManager.getUserById(testUid))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => userDatabaseManager.getUserById(testUid),
          throwsA(isA<Exception>()),
        );
      });

      test('handles network error gracefully', () async {
        // Arrange
        const testUid = 'network-error-user-id';
        final exception = Exception('No internet connection');

        when(() => mockFirebaseUserManager.getUserById(testUid))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => userDatabaseManager.getUserById(testUid),
          throwsA(isA<Exception>()),
        );
      });

      test('works with special characters in uid', () async {
        // Arrange
        const testUid = 'user-id-with-special-chars-!@#\$%';
        final testUser = User(
          uid: testUid,
          email: 'special@example.com',
        );

        when(() => mockFirebaseUserManager.getUserById(testUid))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await userDatabaseManager.getUserById(testUid);

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, testUid);
      });
    });

    group('deleteUser', () {
      test('successfully deletes user from Firebase', () async {
        // Arrange
        const testUid = 'user-to-delete-123';

        when(() => mockFirebaseUserManager.deleteUser(testUid))
            .thenAnswer((_) async {});

        // Act
        await userDatabaseManager.deleteUser(testUid);

        // Assert
        verify(() => mockFirebaseUserManager.deleteUser(testUid)).called(1);
      });

      test('completes successfully even if user does not exist', () async {
        // Arrange
        const testUid = 'nonexistent-user-to-delete';

        when(() => mockFirebaseUserManager.deleteUser(testUid))
            .thenAnswer((_) async {});

        // Act
        await userDatabaseManager.deleteUser(testUid);

        // Assert
        verify(() => mockFirebaseUserManager.deleteUser(testUid)).called(1);
      });

      test('propagates exception when Firebase throws during deletion',
          () async {
        // Arrange
        const testUid = 'user-delete-error';
        final exception = Exception('Failed to delete user: Permission denied');

        when(() => mockFirebaseUserManager.deleteUser(testUid))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => userDatabaseManager.deleteUser(testUid),
          throwsA(isA<Exception>()),
        );
      });

      test('propagates exception on network failure during deletion',
          () async {
        // Arrange
        const testUid = 'user-delete-network-error';
        final exception = Exception('No internet connection during delete');

        when(() => mockFirebaseUserManager.deleteUser(testUid))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => userDatabaseManager.deleteUser(testUid),
          throwsA(isA<Exception>()),
        );
      });

      test('handles concurrent delete operations gracefully', () async {
        // Arrange
        const uid1 = 'user-1';
        const uid2 = 'user-2';

        when(() => mockFirebaseUserManager.deleteUser(uid1))
            .thenAnswer((_) async {});
        when(() => mockFirebaseUserManager.deleteUser(uid2))
            .thenAnswer((_) async {});

        // Act
        await Future.wait([
          userDatabaseManager.deleteUser(uid1),
          userDatabaseManager.deleteUser(uid2),
        ]);

        // Assert
        verify(() => mockFirebaseUserManager.deleteUser(uid1)).called(1);
        verify(() => mockFirebaseUserManager.deleteUser(uid2)).called(1);
      });
    });

    group('Integration scenarios', () {
      test('set and then get user data works correctly', () async {
        // Arrange
        final newUser = User(
          uid: 'integration-test-123',
          email: 'integration@example.com',
          userName: 'integrationuser',
        );

        when(() => mockFirebaseUserManager.setUser(newUser))
            .thenAnswer((_) async {});
        when(() => mockFirebaseUserManager.getUserById(newUser.uid!))
            .thenAnswer((_) async => newUser);

        // Act
        await userDatabaseManager.setUserData(newUser);
        final retrieved = await userDatabaseManager.getUserById(newUser.uid!);

        // Assert
        expect(retrieved, isNotNull);
        expect(retrieved?.email, newUser.email);
        verify(() => mockFirebaseUserManager.setUser(newUser)).called(1);
        verify(() => mockFirebaseUserManager.getUserById(newUser.uid!))
            .called(1);
      });

      test('get current user and then delete works correctly', () async {
        // Arrange
        const testUid = 'integration-delete-123';
        final testUser = User(
          uid: testUid,
          email: 'integration-delete@example.com',
        );

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn(testUid);
        when(() => mockFirebaseUserManager.getUserById(testUid))
            .thenAnswer((_) async => testUser);
        when(() => mockFirebaseUserManager.deleteUser(testUid))
            .thenAnswer((_) async {});

        // Act
        final user = await userDatabaseManager.getUserData();
        if (user != null) {
          await userDatabaseManager.deleteUser(user.uid!);
        }

        // Assert
        expect(user, isNotNull);
        verify(() => mockFirebaseUserManager.deleteUser(testUid)).called(1);
      });
    });
  });
}

