import 'package:app_code/models/user.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    test('generates uid when not provided and setters work', () {
      final user = User(userName: 'Alice', email: 'alice@test.com');

      expect(user.uid, isNotNull);
      expect(user.getUserName(), 'Alice');
      expect(user.isAnonymous, false);
      expect(user.setUserName('Bob'), 1);
      expect(user.getUserName(), 'Bob');
    });

    test('toDatabase and toJson keep fields', () {
      final user = User(uid: 'u1', userName: 'Carol', email: 'c@test.com', isAnonymous: true);

      final db = user.toDatabase();
      final json = user.toJson();

      expect(db['id'], 'u1');
      expect(db['email'], 'c@test.com');
      expect(db['user_name'], 'Carol');

      expect(json['id'], 'u1');
      expect(json['email'], 'c@test.com');
      expect(json['user_name'], 'Carol');
      expect(json['is_anonymous'], true);
    });

    test('fromDatabase and fromJson using FakeFirebaseFirestore', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = await firestore.collection('users').add({
        'email': 'd@test.com',
        'user_name': 'Dave',
        'is_anonymous': true,
      });

      final snap = await docRef.get();

      final fromDb = User.fromDatabase(snap);
      final fromJson = User.fromJson(snap);

      expect(fromDb.uid, docRef.id);
      expect(fromDb.email, 'd@test.com');
      expect(fromDb.getUserName(), 'Dave');

      expect(fromJson.uid, docRef.id);
      expect(fromJson.email, 'd@test.com');
      expect(fromJson.isAnonymous, true);
      expect(fromJson.getUserName(), 'Dave');
    });

    test('handles null userName gracefully', () {
      final user = User(uid: 'u1', email: 'test@test.com', userName: null);

      expect(user.getUserName(), '');
      expect(user.toDatabase()['user_name'], null);
      expect(user.toJson()['user_name'], null);
    });

    test('handles empty userName', () {
      final user = User(uid: 'u1', email: 'test@test.com', userName: '');

      expect(user.getUserName(), '');
      user.setUserName('NewName');
      expect(user.getUserName(), 'NewName');
    });

    test('creates anonymous user correctly', () {
      final user = User(isAnonymous: true, email: 'anon@test.com');

      expect(user.isAnonymous, true);
      expect(user.toJson()['is_anonymous'], true);
    });

    test('handles user with special characters in userName', () {
      final user = User(
        uid: 'u1',
        email: 'special@test.com',
        userName: 'Üser Ñamé 123',
      );

      expect(user.getUserName(), 'Üser Ñamé 123');
      expect(user.toDatabase()['user_name'], 'Üser Ñamé 123');
    });

    test('multiple setUserName calls update correctly', () {
      final user = User(userName: 'First');

      expect(user.setUserName('Second'), 1);
      expect(user.getUserName(), 'Second');
      
      expect(user.setUserName('Third'), 1);
      expect(user.getUserName(), 'Third');
    });

    test('user with provided uid uses that uid', () {
      final user = User(uid: 'custom-id', email: 'test@test.com');

      expect(user.uid, 'custom-id');
    });
  });
}
