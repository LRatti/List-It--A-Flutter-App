# Favorite Supermarket Initialization - Test Suite

## Overview
This test suite (`test/utils/favorite_supermarket_initialization_test.dart`) verifies that the default supermarket is correctly initialized as the favorite on the app's first usage, and that the single-favorite invariant is maintained throughout the application lifecycle.

## Test Groups

### 1. Favorite Supermarket Initialization
Tests covering the core initialization functionality.

#### Test: seedMockDataIfEmpty sets default supermarket as favorite on first install
**Scenario**: Fresh app installation with empty database
**Steps**:
1. Verify database is empty
2. Call `seedMockDataIfEmpty()`
3. Verify supermarkets were created
4. Verify exactly one is marked as favorite
5. Verify it's the default supermarket
6. Verify `getFavoriteSupermarket()` returns the correct one

**Assertions**:
- Database is populated after seeding
- Exactly one favorite supermarket exists
- Favorite is the default "Supermarket"
- Querying favorite returns correct result

**Success Criteria**: ✅ Default supermarket is marked as favorite on first use

---

#### Test: seedMockDataIfEmpty skips seeding if database already has data
**Scenario**: Upgrade scenario where database already contains data
**Steps**:
1. Create initial supermarket with favorite status
2. Verify initial state (1 supermarket)
3. Call `seedMockDataIfEmpty()` (should skip)
4. Verify no additional data was added

**Assertions**:
- Database count remains 1 (not overwritten)
- Initial supermarket is preserved

**Success Criteria**: ✅ Seeding respects existing data

---

#### Test: ensureFavoriteInitialized finds existing favorite without changes
**Scenario**: Database already has a favorite supermarket
**Steps**:
1. Create supermarket with favorite status
2. Verify favorite exists
3. Call `ensureFavoriteInitialized()`
4. Verify favorite is unchanged

**Assertions**:
- Method returns `true`
- Favorite supermarket ID remains the same

**Success Criteria**: ✅ Initialization is idempotent

---

#### Test: ensureFavoriteInitialized auto-selects first visible on upgrade
**Scenario**: Upgrade where database has supermarkets but no favorite is set
**Steps**:
1. Create multiple supermarkets without favorite status
2. Include one hidden supermarket
3. Verify no favorite exists
4. Call `ensureFavoriteInitialized()`
5. Verify first visible supermarket is selected as favorite

**Assertions**:
- Method returns `true`
- A favorite is now set
- Favorite is the first visible supermarket
- Hidden supermarkets are not selected

**Success Criteria**: ✅ Upgrade scenarios are handled gracefully

---

#### Test: ensureFavoriteInitialized handles empty database gracefully
**Scenario**: Initialization called on empty database
**Steps**:
1. Verify database is empty
2. Call `ensureFavoriteInitialized()`
3. Verify method handles gracefully

**Assertions**:
- Method returns `false`
- No exception is thrown
- Database remains empty

**Success Criteria**: ✅ Edge case handled without crashes

---

#### Test: favorite supermarket can be queried after first app usage
**Scenario**: Post-initialization query
**Steps**:
1. Seed mock data (simulating first app startup)
2. Query favorite supermarket
3. Verify all properties are accessible

**Assertions**:
- `getFavoriteSupermarket()` returns non-null
- Favorite has expected name, visibility, and categories
- Favorite is usable by other app components

**Success Criteria**: ✅ Favorite is ready for use immediately

---

#### Test: exactly one supermarket is marked as favorite after seed
**Scenario**: Verifying the single-favorite invariant
**Steps**:
1. Seed mock data
2. Get all supermarkets
3. Count supermarkets with `isFavorite == true`

**Assertions**:
- Count is exactly 1

**Success Criteria**: ✅ Invariant: exactly one favorite always

---

#### Test: default supermarket includes default categories
**Scenario**: Verifying default supermarket is fully functional
**Steps**:
1. Seed mock data
2. Get favorite supermarket
3. Verify it has categories
4. Query categories by supermarket ID

**Assertions**:
- Categories list is not empty
- Category IDs are unique
- Category queries work correctly

**Success Criteria**: ✅ Default supermarket is properly initialized

---

#### Test: setFavoriteSupermarket maintains single favorite invariant
**Scenario**: Changing favorite supermarket
**Steps**:
1. Create two supermarkets (first as favorite)
2. Verify first is favorite
3. Set second as favorite
4. Verify only second is now favorite

**Assertions**:
- Only one supermarket has `isFavorite == true`
- Previous favorite's status is cleared
- Exactly one favorite always exists

**Success Criteria**: ✅ Invariant is maintained on changes

---

### 2. First App Usage Workflow
Integration tests covering complete scenarios.

#### Test: complete workflow: fresh install → favorite available
**Scenario**: Complete first-time app startup
**Steps**:
1. Verify clean database
2. Seed mock data
3. Verify data was seeded
4. Query favorite supermarket
5. Verify properties
6. Verify invariant

**Assertions**:
- Favorite is available after seeding
- Favorite has all required properties
- Invariant is maintained
- Favorite is ready for use (e.g., shopping list creation)

**Success Criteria**: ✅ Full workflow: install → ready to use

---

#### Test: complete workflow: upgrade → favorite auto-initialized
**Scenario**: App upgrade from previous version without favorite
**Steps**:
1. Create legacy database with supermarkets (no favorite)
2. Verify no favorite exists
3. Call startup initialization methods
4. Verify favorite is now available
5. Verify app can use it

**Assertions**:
- `ensureFavoriteInitialized()` returns `true`
- Favorite is selected automatically
- Favorite is usable

**Success Criteria**: ✅ Full workflow: upgrade → auto-initialized

---

## Test Coverage

| Aspect | Coverage | Tests |
|--------|----------|-------|
| Fresh Install | ✅ | 1 dedicated + 1 integration |
| Upgrade Path | ✅ | 1 dedicated + 1 integration |
| Empty Database | ✅ | 1 test |
| Existing Favorite | ✅ | 1 test |
| Multiple Supermarkets | ✅ | 1 test |
| Hidden Supermarkets | ✅ | 1 test |
| Invariant Maintenance | ✅ | 2 tests |
| Query Functionality | ✅ | 3 tests |
| **Total** | | **12 tests** |

## Running the Tests

### Run all favorite supermarket tests
```bash
flutter test test/utils/favorite_supermarket_initialization_test.dart
```

### Run specific test group
```bash
flutter test test/utils/favorite_supermarket_initialization_test.dart -n "Favorite Supermarket Initialization"
flutter test test/utils/favorite_supermarket_initialization_test.dart -n "First App Usage Workflow"
```

### Run specific test
```bash
flutter test test/utils/favorite_supermarket_initialization_test.dart -n "seedMockDataIfEmpty sets default"
```

### Run with verbose output
```bash
flutter test test/utils/favorite_supermarket_initialization_test.dart -v
```

## Test Setup and Teardown

### setUpAll (runs once before all tests)
- Initializes SQLite FFI for testing
- Deletes old test database
- Creates clean database instance

### setUp (runs before each test)
- Clears all relevant database tables
- Ensures isolated test environment
- Prevents cross-test data pollution

## Key Assertions

| Type | Purpose | Example |
|------|---------|---------|
| `expect(value, isNotNull)` | Verify data exists | Favorite is created |
| `expect(value, hasLength(n))` | Count exactly | Exactly 1 favorite |
| `expect(value, isTrue/isFalse)` | Boolean checks | Initialization succeeded |
| `expect(value, equals(x))` | Exact match | Correct supermarket ID |
| `expect(value, isEmpty)` | Empty collections | Database is clean |
| `reason:` | Documentation | Explains assertion intent |

## Edge Cases Tested

1. **Empty Database**: Graceful handling when no supermarkets exist
2. **Hidden Supermarkets**: Correct selection of visible ones
3. **Already Initialized**: Idempotent behavior
4. **Multiple Supermarkets**: Correct selection of first
5. **Upgrade Scenarios**: Auto-initialization with existing data
6. **Invariant Violations**: Proper constraint maintenance

## Success Criteria Summary

✅ Default supermarket is marked as favorite on fresh install
✅ Favorite is auto-initialized on upgrade
✅ Exactly one supermarket is always favorite
✅ Empty database is handled gracefully
✅ Favorite is immediately usable after initialization
✅ Categories are properly loaded with favorite
✅ Invariant is maintained through operations
✅ Complete workflows function end-to-end

## Related Code

- **Implementation**: `lib/utils/favorite_supermarket_initializer.dart`
- **Seed Logic**: `lib/services/mock/mock_data_seed.dart`
- **Database**: `lib/services/database/sqlite/manage_supermarket.dart`
- **Supermarket Model**: `lib/models/supermarket.dart`

## Test Data

### Fresh Install
- Empty database
- `seedMockDataIfEmpty()` called
- Results in: 1 supermarket with categories, marked as favorite

### Upgrade Scenario
- Multiple supermarkets, none marked favorite
- `ensureFavoriteInitialized()` called
- Results in: First visible supermarket marked as favorite

### Multi-Supermarket
- 3 supermarkets created (1 hidden)
- Tests selection and visibility logic
- Verifies invariant enforcement

---

**Total Tests**: 12
**Coverage**: Fresh Install, Upgrade, Edge Cases, Integration
**Status**: ✅ Ready for execution
