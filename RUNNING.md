# Running Autonect

Three ways to run the app, and when each is worth it.

| | Speed to see a change | Runtime speed | Hot reload |
|---|---|---|---|
| **Web, release bundle** | ~2 min rebuild | fast | no |
| **Web, `flutter run`** | ~1 sec | slower | yes |
| **Android APK** | ~6 min build | fastest | yes, over Wi-Fi |

Web is the fast loop for UI work. The phone is the only way to test file
uploads and anything platform-specific.

---

## 1. Web — release bundle (lightest on the machine)

No compile-on-load and no file watcher, so it is the gentlest option on a
laptop that struggles with the debug build.

```powershell
cd D:\Projects-infinity\Autonect-project\autonect
flutter build web --release
npx serve -l 5173 build\web
```

Open <http://localhost:5173>.

**To see new code: rebuild, then hard-refresh.**

```powershell
flutter build web --release
```

`npx serve` keeps running and picks up the new files. In the browser press
**Ctrl+Shift+R** — a normal refresh will serve the cached `main.dart.js` and
you will think nothing changed.

## 2. Web — hot reload

```powershell
flutter run -d chrome --web-port=5173
```

| key | does |
|---|---|
| `r` | hot reload, ~1 second, keeps the current screen and state |
| `R` | hot restart, ~5 seconds, re-runs `main()` |
| `q` | quit |

**Use `R`, not `r`, after any change to `main()`** — new `Get.put`
registrations, bindings, or anything in the DI block. A hot reload does not
re-run `main()`, so a new controller will fail to resolve and the screen throws.

The first load is blank for a while: the debug build compiles in the browser.
On a slow machine give it a few minutes before assuming it is broken.

## 3. Android APK

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

## The port is not optional

The API's CORS allowlist is exactly:

```
http://localhost:5173
https://autonect-adminpanel.vercel.app
```

On **any other port** the UI loads and every API call is blocked by the
browser — no categories, no login, nothing, and the failure is only visible in
the dev console. Serve on **5173** or nothing works.

`5173` is also Vite's default, so another project's dev server may already have
it. If Flutter cannot bind, find the culprit:

```powershell
Get-NetTCPConnection -LocalPort 5173 -State Listen |
  ForEach-Object { Get-CimInstance Win32_Process -Filter "ProcessId = $($_.OwningProcess)" } |
  Select-Object ProcessId, CommandLine
```

To use a different port instead, add it to `CORS_ORIGINS` in **SSM Parameter
Store** at `/autonect/dev/env` and redeploy — not to the repo's `.env`, which
production never reads.

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

## Known limits when running on web

- **File uploads may fail.** KYC documents and the avatar PUT straight to S3,
  cross-origin, under the *bucket's* CORS rules — separate from the API's. Test
  those on the phone.
- **Sessions do not carry over.** Web keeps them in `localStorage`, the phone in
  `SharedPreferences`. Signing in on one does not sign you in on the other.
- No `Platform.isIOS`, no filesystem — a restored draft's photo tiles render a
  placeholder, by design.

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
