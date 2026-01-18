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
  });
}
