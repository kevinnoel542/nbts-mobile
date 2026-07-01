# NBTS Mobile Achievement Log

## Purpose

This file tracks what has been achieved in the mobile app, what changed in Flutter, and what is expected from the Laravel backend so both sides stay aligned.

## Achieved On Mobile

- Set the app API base URL in `lib/core/api/api_config.dart`.
- Updated the current API target to `http://192.168.0.156/api/v1`.
- Added Firebase support for social authentication.
- Added Google Sign-In support using the native Google account picker flow.
- Changed Google login away from Firebase's browser-based generic provider flow.
- Kept Apple login available through Firebase OAuth provider flow.
- Added mobile handling for `POST /api/v1/auth/firebase`.
- Added donor profile completion routing after Firebase login.
- Added a complete profile screen for first-time social login users.
- Added persistent login storage with `shared_preferences`, so users do not need to enter email/password every time.
- Updated splash behavior to open the dashboard directly when a valid token already exists.
- Added QR code rendering in Flutter using Laravel-provided donor card QR payload.
- Updated the welcome screen to start with sign in first, then create account.
- Removed Microsoft social login option from the mobile UI.
- Added Google and Apple icons from Icons8 assets.
- Improved sign-in and register buttons with a cleaner modern style.
- Improved social auth buttons with better spacing, shadows, icon badges, and disabled states.
- Improved login form fields to look cleaner and more mobile-friendly.
- Updated Kotlin Gradle plugin configuration to reduce Flutter build warnings.
- Confirmed Firebase Google login succeeds on the phone when Firebase returns a user ID.
- Added clearer login error display using a SnackBar when the backend login step fails.

## Current Mobile Status

Firebase login is working, but dashboard navigation depends on Laravel accepting the Firebase token.

The mobile app currently posts Firebase login data to:

```text
POST http://192.168.0.156/api/v1/auth/firebase
```

The tested response from that endpoint was:

```text
404 Not Found
```

That means the mobile app can sign in with Firebase, but cannot finish backend authentication until Laravel exposes the endpoint on the same host and path.

## Expected From Laravel

Laravel should provide this endpoint:

```text
POST /api/v1/auth/firebase
```

Expected request body from Flutter:

```json
{
  "provider": "google.com",
  "firebase_id_token": "firebase-id-token-here",
  "id_token": "firebase-id-token-here",
  "email": "donor@example.com",
  "name": "Donor Name",
  "photo_url": "https://example.com/photo.jpg",
  "firebase_uid": "firebase-user-id"
}
```

Laravel should:

- Verify the Firebase ID token.
- Confirm the Firebase project ID, token signature, expiry, issuer, audience, and subject.
- Find an existing user by `firebase_uid` or email.
- Create a donor user if no account exists.
- Save `firebase_uid` and `firebase_provider` on the user.
- Create a donor profile record if missing.
- Return the normal mobile auth response with a token and user data.

Expected successful response shape:

```json
{
  "token": "sanctum-token-here",
  "user": {
    "id": 1,
    "name": "Donor Name",
    "email": "donor@example.com",
    "role": "donor"
  }
}
```

The response may also wrap data inside `data.user`, as the mobile app supports both formats.

## Laravel Commands To Check

Run inside the Laravel project:

```powershell
cd C:\Users\PRODUCTION\Desktop\UJUGU\NBTS-laravel
php artisan route:list | findstr firebase
php artisan migrate
php artisan optimize:clear
```

If the API is served with Laravel artisan on port `8003`, run:

```powershell
php artisan serve --host=0.0.0.0 --port=8003
```

Then the mobile API base URL should be:

```text
http://192.168.0.156:8003/api/v1
```

If the API is served by Apache/Nginx at the root host, then the current mobile API base URL is correct:

```text
http://192.168.0.156/api/v1
```

## Important Notes

- Firebase login success does not automatically mean Laravel login success.
- The dashboard opens only after Laravel returns a valid app token.
- If the app remains on the login screen after Google login, check the Laravel response for `/api/v1/auth/firebase`.
- Current confirmed blocker: `/api/v1/auth/firebase` returned `404 Not Found` on `http://192.168.0.156`.
