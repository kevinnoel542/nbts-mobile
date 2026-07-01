# NBTS Mobile Achievement Log

## Purpose

This file tracks what has been achieved in the mobile app, what changed in Flutter, and what is expected from the Laravel backend so both sides stay aligned.

## Achieved On Mobile

- Set the app API base URL in `lib/core/api/api_config.dart`.
- Updated the current API target to `http://192.168.0.156:8003/api/v1`.
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
POST http://192.168.0.156:8003/api/v1/auth/firebase
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

If the API is served by Apache/Nginx at the root host without port `8003`, then update the mobile API base URL back to:

```text
http://192.168.0.156/api/v1
```

## Important Notes

- Firebase login success does not automatically mean Laravel login success.
- The dashboard opens only after Laravel returns a valid app token.
- If the app remains on the login screen after Google login, check the Laravel response for `/api/v1/auth/firebase`.
- Current confirmed blocker: `/api/v1/auth/firebase` returned `404 Not Found` on `http://192.168.0.156`.

## 2026-07-01 API Port Update

Mobile was updated to use:

```text
http://192.168.0.156:8003/api/v1
```

Reason: the phone showed an HTML `404 Not Found` page from `http://192.168.0.156/api/v1/...`, which means the app was reaching the web/admin host instead of the Laravel API route.

Laravel/backend should confirm that this route exists on port `8003`:

```text
POST /api/v1/auth/firebase
```

Mobile also now converts HTML error pages into a clearer message:

```text
API route not found. Check the Laravel API URL and port.
```
## 2026-07-01 Social Profile Completion Implementation

Mobile now fully supports the recommended Google/Apple onboarding flow:

1. User signs in with Google or Apple.
2. Flutter sends the Firebase ID token to Laravel through `POST /api/v1/auth/firebase`.
3. Flutter reads Laravel user data.
4. If `profile_complete` is `false`, Flutter opens the Complete Profile screen.
5. User fills donor details.
6. Flutter sends the completed details to `PUT /api/v1/profile`.
7. Flutter refreshes the current user, then opens the dashboard.

Mobile now reads this field from Laravel when available:

```json
{
  "profile_complete": false
}
```

Laravel should return `profile_complete` on auth and profile responses. Mobile also supports these aliases as fallback:

```text
profile_complete
is_profile_complete
profileComplete
donor_profile_complete
```

The Complete Profile screen now sends these fields to Laravel:

```json
{
  "name": "Donor Name",
  "phone": "+255712000000",
  "blood_group": "O+",
  "gender": "male",
  "region": "Dar es Salaam",
  "date_of_birth": "1998-01-20",
  "address": "Optional address",
  "preferred_center_id": 1,
  "emergency_contact_name": "Optional contact",
  "emergency_contact_phone": "+255713000000",
  "push_notifications_enabled": true,
  "sms_reminders_enabled": true,
  "share_anonymized_data": false,
  "language": "en"
}
```

Required for Laravel:

- New Google/Apple users should not be treated as complete donors immediately.
- If required donor fields are missing, return `profile_complete: false`.
- After `PUT /api/v1/profile` saves required donor fields, return `profile_complete: true`.
- `PUT /api/v1/profile` should save user fields and donor profile fields together.
- `GET /api/v1/profile` or `GET /api/v1/user` should return the same profile completion flag.

## 2026-07-01 Dashboard Access Guard Update

Mobile was tightened so a social login user cannot reach the dashboard just because Laravel returns an auth token.

New mobile rule:

- If `profile_complete` is `false`, open Complete Profile.
- If `profile_complete` is `true` but required donor fields are missing, still open Complete Profile.
- If `profile_complete` is missing, Flutter checks required donor fields directly.

Required donor fields checked by Flutter:

```text
phone
blood_group
gender
region
date_of_birth
```

After Google/Apple Firebase login, Flutter now calls Laravel auth first, then fetches the fresh current user/profile before choosing dashboard or Complete Profile.

Laravel should not auto-mark newly created Google/Apple users as complete. A deleted/new Google account should be created as an incomplete donor until `PUT /api/v1/profile` saves the required donor fields.


## 2026-07-01 Language Validation Fix

Mobile now sends language as Laravel-friendly short codes:

`	ext
English -> en
Swahili -> sw
` 

This fixes Laravel validation errors such as The selected language is invalid. during PUT /api/v1/profile.

## 2026-07-01 Optional Email Registration

Mobile registration now allows donors to register with phone number only.

Flutter behavior:

- Phone remains required.
- Email is optional.
- If email is empty, Flutter omits `email` from `POST /api/v1/auth/register`.
- If email is provided, Flutter validates basic email format before sending.

Laravel should update registration validation so email is nullable/optional when phone is present. Suggested rule shape:

```text
phone: required, unique users/donor phone rule
email: nullable, email, unique users email rule
```

Login already supports `identifier`, so users can sign in using either phone number or email.

## 2026-07-01 Centers UI Detail Update

Mobile now shows richer donation center cards when Laravel provides the data.

Flutter displays these center fields from the centers API:

```text
name
address
phone
opening_hours / hours / working_hours / open_hours
services / service_list
is_open / open / status_open
distance_km
wait_time / estimated_wait
capacity_label / capacity / availability
```

The Centers screen no longer opens booking by tapping the whole card silently. It now shows a clear `Book here` button on each center card.

Laravel should make sure the centers endpoint returns useful values for:

- phone
- opening hours
- services
- open/closed status
- address


## 2026-07-01 Dynamic Appointment Slots

Mobile booking now supports Laravel-controlled appointment times and is aligned with the existing Laravel available-slots route.

Flutter now calls this endpoint after the donor selects a center and date:

```text
GET /api/v1/blood-centers/1/available-slots?date=2026-07-01
```

Expected Laravel response:

```json
[
  {
    "time": "08:00",
    "available": true
  },
  {
    "time": "09:30",
    "available": false,
    "reason": "Full"
  },
  {
    "time": "11:00",
    "available": false,
    "reason": "Center closed"
  }
]
```

Flutter supports these slot field aliases:

```text
time / slot_time / starts_at / start_time / scheduled_time
available / is_available / open
reason / message / status_label
```

If Laravel has not added the endpoint yet, Flutter falls back to standard times so the app does not break. Laravel should still do the final availability check inside `POST /api/v1/appointments` and `PUT /api/v1/appointments/{id}` because a slot can become full while the donor is on the booking screen.


