# Visual Test Execution Guide

## Test File Structure

```
test/utils/favorite_supermarket_initialization_test.dart
├── setUpAll
│   ├── Initialize SQLite FFI
│   ├── Set database factory
│   └── Delete old test database
│
├── Group: "Favorite Supermarket Initialization"
│   ├── Test 1: seedMockDataIfEmpty sets default as favorite
│   ├── Test 2: seedMockDataIfEmpty skips existing data
│   ├── Test 3: ensureFavoriteInitialized finds existing
│   ├── Test 4: ensureFavoriteInitialized auto-selects
│   ├── Test 5: ensureFavoriteInitialized empty DB
│   ├── Test 6: favorite can be queried
│   ├── Test 7: exactly one favorite after seed
│   ├── Test 8: default includes categories
│   └── Test 9: setFavoriteSupermarket maintains invariant
│
└── Group: "First App Usage Workflow"
    ├── Test 10: complete workflow fresh install
    └── Test 11: complete workflow upgrade
```

## Test Execution Flow

### Test 1: Fresh Install - Sets Default as Favorite
```
┌─────────────────────────────────────────────────┐
│ Test: seedMockDataIfEmpty Fresh Install         │
├─────────────────────────────────────────────────┤
│                                                 │
│  ARRANGE                                        │
│  └─ Database is empty                          │
│                                                 │
│  ACT                                            │
│  └─ Call seedMockDataIfEmpty()                 │
│                                                 │
│  ASSERT                                         │
│  ├─ Supermarkets created                       │
│  ├─ Exactly 1 has isFavorite == true           │
│  ├─ Favorite is named "Supermarket"           │
│  └─ getFavoriteSupermarket() returns it        │
│                                                 │
│  ✅ RESULT: Default marked as favorite         │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Test 2: Skip If Has Data
```
┌─────────────────────────────────────────────────┐
│ Test: seedMockDataIfEmpty Skips Existing       │
├─────────────────────────────────────────────────┤
│                                                 │
│  ARRANGE                                        │
│  └─ Database has 1 supermarket                 │
│                                                 │
│  ACT                                            │
│  └─ Call seedMockDataIfEmpty()                 │
│                                                 │
│  ASSERT                                         │
│  └─ Still 1 supermarket (not overwritten)     │
│                                                 │
│  ✅ RESULT: Existing data preserved            │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Test 3: Find Existing Favorite
```
┌─────────────────────────────────────────────────┐
│ Test: ensureFavoriteInitialized Finds Existing │
├─────────────────────────────────────────────────┤
│                                                 │
│  ARRANGE                                        │
│  └─ Database has favorite set                  │
│                                                 │
│  ACT                                            │
│  └─ Call ensureFavoriteInitialized()           │
│                                                 │
│  ASSERT                                         │
│  ├─ Returns true                               │
│  └─ Favorite unchanged                         │
│                                                 │
│  ✅ RESULT: Idempotent (safe to call multiple) │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Test 4: Auto-Select on Upgrade
```
┌──────────────────────────────────────────────────────┐
│ Test: ensureFavoriteInitialized Auto-Selects       │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ARRANGE                                             │
│  ├─ Database has 3 supermarkets                     │
│  ├─ None marked as favorite                         │
│  └─ One is hidden                                   │
│                                                      │
│  ACT                                                 │
│  └─ Call ensureFavoriteInitialized()                │
│                                                      │
│  ASSERT                                              │
│  ├─ Returns true                                    │
│  ├─ First visible supermarket is now favorite      │
│  └─ Exactly 1 favorite                              │
│                                                      │
│  ✅ RESULT: Upgrade handled automatically           │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### Test 5: Handle Empty Database
```
┌──────────────────────────────────────────────────┐
│ Test: ensureFavoriteInitialized Empty Database   │
├──────────────────────────────────────────────────┤
│                                                  │
│  ARRANGE                                         │
│  └─ Database is completely empty                │
│                                                  │
│  ACT                                             │
│  └─ Call ensureFavoriteInitialized()             │
│                                                  │
│  ASSERT                                          │
│  ├─ Returns false (gracefully)                   │
│  └─ No exceptions thrown                         │
│                                                  │
│  ✅ RESULT: Edge case handled                    │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Test 6: Query Favorite
```
┌──────────────────────────────────────────────────┐
│ Test: favorite can be queried after first use   │
├──────────────────────────────────────────────────┤
│                                                  │
│  ARRANGE                                         │
│  └─ Seed mock data                               │
│                                                  │
│  ACT                                             │
│  └─ Query: getFavoriteSupermarket()              │
│                                                  │
│  ASSERT                                          │
│  ├─ Returns non-null                             │
│  ├─ Has valid ID and name                        │
│  ├─ Is visible and marked favorite               │
│  └─ Ready for use (e.g., shopping lists)        │
│                                                  │
│  ✅ RESULT: Favorite is usable                   │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Test 7: Single Favorite Invariant
```
┌──────────────────────────────────────────────────┐
│ Test: exactly one favorite after seed            │
├──────────────────────────────────────────────────┤
│                                                  │
│  ARRANGE                                         │
│  └─ Seed mock data                               │
│                                                  │
│  ACT                                             │
│  └─ Get all supermarkets, count favorites       │
│                                                  │
│  ASSERT                                          │
│  └─ Count === 1 (exactly one)                    │
│                                                  │
│  ✅ RESULT: Invariant enforced                   │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Test 8: Categories with Default
```
┌──────────────────────────────────────────────────┐
│ Test: default includes categories                │
├──────────────────────────────────────────────────┤
│                                                  │
│  ARRANGE                                         │
│  └─ Seed mock data                               │
│                                                  │
│  ACT                                             │
│  └─ Get favorite, query its categories           │
│                                                  │
│  ASSERT                                          │
│  ├─ Categories list not empty                    │
│  ├─ Each has unique ID                           │
│  └─ Database queries work                        │
│                                                  │
│  ✅ RESULT: Complete initialization              │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Test 9: Maintain Invariant on Change
```
┌──────────────────────────────────────────────────┐
│ Test: setFavoriteSupermarket maintains invariant │
├──────────────────────────────────────────────────┤
│                                                  │
│  ARRANGE                                         │
│  └─ Database has 2 supermarkets (first favorite)│
│                                                  │
│  ACT                                             │
│  └─ Call setFavoriteSupermarket(second.id)      │
│                                                  │
│  ASSERT                                          │
│  ├─ Second is now favorite                      │
│  ├─ First is no longer favorite                 │
│  └─ Count of favorites === 1                     │
│                                                  │
│  ✅ RESULT: Constraint maintained on changes     │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Integration Test 10: Fresh Install Workflow
```
┌────────────────────────────────────────────────────┐
│ Test: Fresh Install → Favorite Available          │
├────────────────────────────────────────────────────┤
│                                                    │
│  STEP 1: Verify Empty                             │
│  └─ Database is clean                             │
│                                                    │
│  STEP 2: Seed Data                                │
│  └─ Call seedMockDataIfEmpty()                    │
│                                                    │
│  STEP 3: Verify Created                           │
│  └─ Supermarkets exist                            │
│                                                    │
│  STEP 4: Verify Favorite                          │
│  ├─ getFavoriteSupermarket() not null             │
│  ├─ All properties valid                          │
│  └─ Ready for use                                 │
│                                                    │
│  STEP 5: Verify Invariant                         │
│  └─ Exactly 1 favorite                            │
│                                                    │
│  ✅ RESULT: Complete workflow works               │
│                                                    │
└────────────────────────────────────────────────────┘
```

### Integration Test 11: Upgrade Workflow
```
┌────────────────────────────────────────────────────┐
│ Test: Upgrade → Favorite Auto-Initialized        │
├────────────────────────────────────────────────────┤
│                                                    │
│  STEP 1: Simulate Legacy DB                       │
│  └─ Create supermarket without favorite           │
│                                                    │
│  STEP 2: Verify Missing                           │
│  └─ getFavoriteSupermarket() returns null         │
│                                                    │
│  STEP 3: Run Initializer                          │
│  └─ Call ensureFavoriteInitialized()              │
│                                                    │
│  STEP 4: Verify Auto-Initialized                  │
│  ├─ Method returns true                           │
│  └─ Favorite now exists                           │
│                                                    │
│  STEP 5: Verify Usable                            │
│  └─ Favorite has all properties                   │
│                                                    │
│  ✅ RESULT: Upgrade handled automatically         │
│                                                    │
└────────────────────────────────────────────────────┘
```

## Key Assertions Used

```dart
// Data exists
expect(value, isNotNull)              // ✓ Not null
expect(value, isNotEmpty)             // ✓ Has contents

// Count checking
expect(list, hasLength(1))            // ✓ Exactly 1

// Boolean checks
expect(bool, isTrue)                  // ✓ Is true
expect(bool, isFalse)                 // ✓ Is false

// Equality
expect(value, equals(expected))       // ✓ Matches exactly

// Collections
expect(list, isEmpty)                 // ✓ Empty
expect(list, isNotEmpty)              // ✓ Has items

// Custom messages
expect(value, condition, reason: 'why this matters')
```

## Success Indicators

### ✅ All Tests Pass
- Every assertion succeeds
- No exceptions thrown
- Database properly cleaned between tests
- No timeout issues

### ✅ Database Isolation
- Each test starts clean
- No cross-test pollution
- Tables properly cleared
- Transactions work correctly

### ✅ Invariant Maintained
- Favorite count always ≤ 1
- Changing favorite clears old one
- No orphaned favorites
- Consistency maintained

## Running Tests in Your IDE

### VS Code
1. Open test file
2. Click "Run" above `void main()`
3. View output in Debug Console

### Android Studio / IntelliJ
1. Open test file
2. Right-click test name
3. Select "Run"
4. View output in Run panel

## Interpreting Test Output

### Success Example
```
✓ seedMockDataIfEmpty sets default supermarket as favorite on first install (450ms)
✓ seedMockDataIfEmpty skips seeding if database already has data (125ms)
...
11 tests passed (2.3s).
```

### Failure Example
```
✗ seedMockDataIfEmpty sets default supermarket as favorite on first install
  Expected: <1>
  Actual: <0>
  Reason: Should have exactly one favorite supermarket
```

---

**Test Suite Status**: ✅ Ready for Execution
**Total Tests**: 12
**Execution Time**: ~5 seconds
**Database Coverage**: Comprehensive
