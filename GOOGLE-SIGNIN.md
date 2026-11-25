# Google sign-in — app side

The backend half is **done and live** as of 24 Nov 2026 (release `6b4f2f1`).
`POST /v1/auth/social` verifies Google sign-in and issues tokens. Nothing is
needed from me to start; no new keys are needed from you.

The API call is also already written: `AuthApiRepository.social(...)` in
`lib/data/repositories/auth_api_repository.dart:85` sends the request and
persists the token pair on success. What is missing is only the SDK that
produces the token, and the button that calls it —
`lib/view/screens/auth/login.dart:239` is still `onTap: () {}`.

---

## 1. The one thing that trips everyone up

`google_sign_in` gives you a **Google** `idToken`. **The server rejects that
one.** Sign in to Firebase with it first and send **Firebase's** token.

```dart
// pubspec.yaml: firebase_auth, google_sign_in  (firebase_core is already in
// the project for push)

final googleUser = await GoogleSignIn().signIn();
if (googleUser == null) return;                   // user cancelled
final googleAuth = await googleUser.authentication;

final cred = await FirebaseAuth.instance.signInWithCredential(
  GoogleAuthProvider.credential(
    idToken: googleAuth.idToken,
    accessToken: googleAuth.accessToken,
  ),
);

final firebaseToken = await cred.user!.getIdToken();   // <-- send THIS

final result = await authRepo.social(
  provider: 'GOOGLE',
  idToken: firebaseToken!,
  role: selectedRole,        // AppRole? — see step 2
);
```

Send `provider: 'GOOGLE'` exactly (uppercase). `'APPLE'` works the same way
when Apple sign-in is added.

## 2. Role is required on the first sign-in only

We cannot guess whether a new person is a Buyer, Supplier or Electrician, so:

- **Returning user** → omit `role`, you get tokens straight away.
- **Brand-new user with no `role`** → `400` with
  `error.code = VALIDATION_ERROR` and
  `error.details = [{"path": "role", "message": "Required"}]`.
  Show the role picker, then call `social(...)` again with the same token plus
  `role`. (`FieldError.listFrom` in `lib/data/core/api_error.dart:45` already
  parses that array, so check for `path == 'role'`.)

The simplest flow that avoids a second round trip: ask for the role **before**
the Google button on the sign-up screen and always pass it; it is ignored once
the account exists.

Only `BUYER`, `SUPPLIER`, `ELECTRICIAN` are accepted — `AppRole.wire` already
sends the right strings. `ADMIN` is refused.

## 3. Errors to handle

| Status | `error.code` | Meaning | Do this |
|---|---|---|---|
| 200 | — | Signed in | Tokens are already persisted by `_persistIfOk` |
| 400 | `VALIDATION_ERROR` | First sign-in, no role (see above) | Show role picker, retry |
| 401 | `UNAUTHORIZED` / `INVALID_CREDENTIALS` | Token invalid, expired, revoked, or the Google account has no verified email | `FirebaseAuth.instance.signOut()`, ask them to try again |
| 403 | `ACCOUNT_SUSPENDED` | Account suspended or banned | Show "contact support", do **not** retry |
| 500 | — | Our side (Firebase unreachable from the server) | Offer retry later; not a bad login |

Both `validationError` and `accountSuspended` already exist in `ApiErrorCode`,
so no enum change is needed and the `switch` in `auth_controller.dart` keeps
compiling.

## 4. Firebase console — one step push did not need

Push only needed `google-services.json`. Google sign-in **also** needs the
signing certificate fingerprints, or `signInWithCredential` throws
`PlatformException(sign_in_failed … ApiException: 10)`:

1. Firebase console → project **autonect1** → Authentication → Sign-in method →
   enable **Google**.
2. Project settings → the Android app → **add SHA-1 and SHA-256** for every key
   that signs a build: your debug key, the upload key, and Play's app signing
   key (Play Console → Setup → App integrity).
3. **Re-download `google-services.json`** afterwards and replace the one in the
   repo.
4. iOS later: add the `REVERSED_CLIENT_ID` URL scheme, and Apple requires Apple
   sign-in alongside Google once it ships.

The Firebase Android app must use the real package name. This is the same
blocker as the Play upload: **`com.example.autonect` has to be renamed** (Play
rejects `com.example.*`, and the package name can never be changed after the
first upload).

## 5. What the server does with the token

So you know what it will and will not accept:

- Verified with Firebase Admin, including a revocation check — a token minted
  before the account was disabled will not open a session.
- The token's sign-in provider must match `provider`. An anonymous,
  email-link or custom Firebase token cannot pass as a Google login.
- Email must be verified by Google, otherwise `401`.
- Email, name and the Firebase `uid` are taken from the token only — anything
  you put in the request body is ignored.
- If the email already has a password account, it is **linked** and activated,
  so someone who signed up with a password and never entered the OTP lands on
  their existing account rather than a duplicate.
- Accounts created this way have **no password**. Password login returns
  `INVALID_CREDENTIALS` for them; `/v1/auth/forgot` still works if they want to
  add one later.

## Done when

- [ ] Tapping "Continue With Google" signs in and lands on the right dashboard
      for the role.
- [ ] A new account asked for a role once, and the second attempt succeeded.
- [ ] Killing and reopening the app keeps the session (tokens persisted).
- [ ] A release-signed build (upload key SHA added) also works, not just debug.

Backend contract reference: `docs/google-sign-in.md` in the backend repo.
Anything behaving differently from the table above, send me the status code and
`error.code` and I will look at the server side.
