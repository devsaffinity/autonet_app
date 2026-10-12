# Running Autonect

Android and iOS only — there is no web build. The phone is the only place the
app runs, and the only way to test file uploads and anything platform-specific.

---

## Android APK

```powershell
flutter build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk` (~60 MB, universal —
installs on any Android phone).

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Builds are signed with **debug keys**, so uninstall any older Autonect build
first rather than installing over it.

### Wireless hot reload on a real device

Once paired, `flutter run` gives the same `r` / `R` loop as web.

1. Phone: Settings → About phone → tap **Build number** ×7
2. Developer options → **Wireless debugging** → on
3. **Pair device with pairing code** — note the `IP:port` and the **6-digit**
   code, and leave the dialog open

```powershell
adb pair 192.168.x.x:PORT 123456
adb devices          # mDNS usually reconnects it on its own afterwards
flutter run
```

The pairing survives reboots; the connection does not. If it drops, toggle
Wireless debugging off and on — you never need to pair again.

---

## Backend

Deploys automatically on push to `main`: `verify.yml` runs the suite, then
`deploy.yml` ships it and runs `prisma migrate deploy`. Check the repo's
**Actions** tab to confirm a push landed.

To apply migrations by hand:

```bash
cd ../autonect-backend
npx prisma migrate deploy
npx prisma migrate status   # applied vs pending
```

The RDS instance is **IP-allowlisted**, so both fail with `P1001` from an
address that is not on the list. `npm test` skips 69 e2e tests without a
database and still reports success — a green run there does not mean the
DB-backed paths passed.

---

## Blockers worth knowing before you test

- **Signup needs an emailed OTP**, and `MAIL_FROM` is still Resend's sandbox
  sender — the code only reaches the API-key owner. Fix that env var or read
  the code from the server log.
- **No demo account can log in.** Every seeded one has `passwordHash: null`, on
  purpose. Sign up your own.
- **Auth is rate limited** to 20 requests per 15 minutes across login, signup,
  OTP verify and resend combined. A login on an unverified account spends two.
- **A supplier cannot be approved from the app.** There is no admin client, so
  approval is `PATCH /v1/admin/kyc/:userId` with an admin token. Until then a
  supplier stops at "Wait for Admin Approval".
