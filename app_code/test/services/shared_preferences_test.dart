import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    // Initialize mock SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  test('SharedPreferences can set and get boolean values', () async {
    final prefs = await SharedPreferences.getInstance();

    // Set a boolean value
    await prefs.setBool('first_time_visit', false);

    // Get the value
    final value = prefs.getBool('first_time_visit');
    expect(value, isFalse);
  });

  test('SharedPreferences returns default on missing key', () async {
    final prefs = await SharedPreferences.getInstance();

    // Get a non-existent key with default value
    final value = prefs.getBool('non_existent_key') ?? true;
    expect(value, isTrue);
  });

  test('SharedPreferences persists values across instances', () async {
    // Set value in first instance
    var prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_key', true);

    // Create new instance and verify value persists
    prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('auth_key');
    expect(value, isTrue);
  });

  test('SharedPreferences can handle multiple keys', () async {
    final prefs = await SharedPreferences.getInstance();

    // Set multiple values
    await prefs.setBool('first_time_visit', false);
    await prefs.setString('user_email', 'test@example.com');
    await prefs.setInt('session_count', 5);

    // Retrieve values
    expect(prefs.getBool('first_time_visit'), isFalse);
    expect(prefs.getString('user_email'), 'test@example.com');
    expect(prefs.getInt('session_count'), 5);
  });

  test('SharedPreferences can remove values', () async {
    final prefs = await SharedPreferences.getInstance();

    // Set a value
    await prefs.setBool('temp_key', true);
    expect(prefs.getBool('temp_key'), isTrue);

    // Remove the value
    await prefs.remove('temp_key');
    expect(prefs.getBool('temp_key'), isNull);
  });

  test('SharedPreferences can clear all values', () async {
    final prefs = await SharedPreferences.getInstance();

    // Set multiple values
    await prefs.setBool('key1', true);
    await prefs.setString('key2', 'value');
    expect(prefs.getKeys().isNotEmpty, isTrue);

    // Clear all
    await prefs.clear();
    expect(prefs.getKeys().isEmpty, isTrue);
  });
}
