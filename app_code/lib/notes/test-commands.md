# Test Commands (Flutter)

Set the working directory once per session.

```powershell
cd "c:\Users\leona\LR\UNI\ANNO VI\DIMA\Project\app\DIMA\app_code"
```

## Common runs

```powershell
flutter test
```
Run the entire unit and widget test suite.

```powershell
flutter test test\path\to\file_test.dart
```
Run only a specific test file.

```powershell
flutter test --name "partial test name"
```
Run tests whose descriptions contain the provided string.

```powershell
flutter test -r expanded
```
Show verbose output (useful when diagnosing failures).

## Coverage quick start

```powershell
flutter test --coverage
```
Generate coverage data to coverage\lcov.info. For per-file breakdown or HTML generation, see lib/notes/test_coverage_commands.txt.
