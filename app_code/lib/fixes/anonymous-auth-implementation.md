# Anonymous Authentication Implementation

## Overview
The app now properly distinguishes between anonymous users and authenticated users using Firebase's built-in `isAnonymous` property.

## How It Works

### 1. User Model Enhancement
The `User` model now includes an `isAnonymous` field:
- `isAnonymous = true`: User is signed in anonymously (no email/password)
- `isAnonymous = false`: User is fully authenticated (with email/password or OAuth)

### 2. Auth Provider
The `authProvider` automatically tracks authentication state changes:
- Listens to Firebase's `authStateChanges()` stream
- Automatically updates when anonymous user converts to authenticated
- **Notifies all listeners** (including UI) when authentication state changes

### 3. Automatic UI Updates
The home page profile screen automatically reacts:
- **Anonymous users**: See "Sign In" button
- **Authenticated users**: See "Logout" and "Settings" buttons

## Key Features

### Seamless Conversion
When an anonymous user signs in or registers:
1. Firebase automatically converts the anonymous account
2. The `authProvider` stream emits the updated user
3. UI automatically updates to show authenticated state
4. **No manual refresh needed** - it's reactive!

### Method: Link Anonymous Account
Use `AuthService.linkAnonymousWithEmailPassword()` to convert an anonymous user:

```dart
// When anonymous user wants to register
final user = await AuthService.linkAnonymousWithEmailPassword(email, password);
// authProvider automatically notifies all listeners
// UI updates automatically
```

## Usage Examples

### In Sign-In Screen
```dart
// Option 1: Sign in existing user (replaces anonymous session)
final user = await AuthService.signIn(email, password);
if (user != null) {
  Navigator.pop(context); // Returns to home, authProvider updates automatically
}
```

### In Sign-Up Screen
```dart
// Option 1: Create new account (for anonymous users who want to keep their data)
final user = await AuthService.linkAnonymousWithEmailPassword(email, password);

// Option 2: Create completely new account (replaces anonymous session)
final user = await AuthService.signUp(email, password);

if (user != null) {
  Navigator.pop(context); // Returns to home, authProvider updates automatically
}
```

### In Profile Screen
```dart
// The UI automatically adapts based on user.isAnonymous
Consumer(
  builder: (context, ref, child) {
    final authState = ref.watch(authProvider);
    
    return authState.when(
      data: (user) {
        if (user == null) return LoginPrompt();
        
        if (user.isAnonymous) {
          return SignInButton(); // Show for anonymous users
        } else {
          return LogoutButton(); // Show for authenticated users
        }
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  },
)
```

## Benefits

1. **Automatic Reactivity**: UI updates automatically when auth state changes
2. **No Manual Refresh**: The StreamProvider handles everything
3. **Firebase Native**: Uses Firebase's built-in `isAnonymous` property
4. **Type-Safe**: The User model clearly indicates authentication status
5. **Seamless UX**: Users can browse anonymously, then sign in without losing data

## Testing Checklist

- [ ] Anonymous user sees "Sign In" button
- [ ] Anonymous user can browse app features
- [ ] When anonymous user signs in, UI updates to show "Logout" button
- [ ] When anonymous user registers, UI updates to show "Logout" button
- [ ] Authenticated user sees "Logout" and "Settings" buttons
- [ ] After logout, user is signed in anonymously again
- [ ] Data persists when linking anonymous account

## Important Notes

- The `authProvider` uses `authStateChanges()` which automatically detects when an anonymous account is linked
- No need to manually call `ref.refresh()` or similar - the stream handles it
- Firebase preserves data when linking anonymous account (UID stays the same)
- If user signs out, they become anonymous again (if you call `ensureAuthenticated()`)
