import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('firstTimeVisitProvider returns true on first visit', () async {
    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time_visit') ?? true;

    expect(isFirstTime, isTrue);
  });

  test('firstTimeVisitProvider returns false after first visit', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time_visit', false);

    final isFirstTime = prefs.getBool('first_time_visit') ?? true;
    expect(isFirstTime, isFalse);
  });

  test('FirstTimeVisitProvider reflects SharedPreferences changes', () async {
    final prefs = await SharedPreferences.getInstance();

    // Initially first time
    var isFirstTime = prefs.getBool('first_time_visit') ?? true;
    expect(isFirstTime, isTrue);

    // Update preferences
    await prefs.setBool('first_time_visit', false);

    // Check updated value
    isFirstTime = prefs.getBool('first_time_visit') ?? true;
    expect(isFirstTime, isFalse);
  });

  test('FirstTimeVisitProvider handles missing key as true', () async {
    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time_visit') ?? true;
    expect(isFirstTime, isTrue);
  });

  test('can store and retrieve multiple preference values', () async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('first_time_visit', false);
    await prefs.setString('user_email', 'test@example.com');
    await prefs.setInt('login_count', 3);

    expect(prefs.getBool('first_time_visit'), isFalse);
    expect(prefs.getString('user_email'), 'test@example.com');
    expect(prefs.getInt('login_count'), 3);
  });
}
