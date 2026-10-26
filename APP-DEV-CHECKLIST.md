# Autonect — what the app side still needs

**Written for: the Flutter app developer.** The backend is finished and live:
billing (through the stores, via RevenueCat) and push notifications are both
implemented and deployed. The remaining work is in the app and in the store
accounts, and **two items block everything else** — the package name and the
signing key.

Please work through the list and send back the items in section 0.

---

## 0. What to send back

| # | What | Notes |
|---|---|---|
| 1 | The **final package name / bundle id** | e.g. `uk.co.autonect.app`. Needed before anything else can be registered. |
| 2 | Confirmation the **upload keystore** exists and is backed up | Do **not** send the keystore or its passwords. |
| 3 | **SHA-1 and SHA-256** of the upload certificate (and the Play App Signing certificate once Play shows it) | Needed to register the app in Firebase. |
| 4 | Confirmation the signed build is on a **Play internal testing track** | A link to the track is enough. |
| 5 | The **Play service account JSON** | RevenueCat needs it to verify Android purchases. Send it privately — not over chat or email if avoidable. |
| 6 | Result of the push wiring check | `POST /v1/devices/token/test` returning `sent: 1` and the phone buzzing. |

Later, only when iOS starts: bundle id, APNs auth key (`.p8`), and the App
Store Connect in-app purchase key (`.p8` + Key ID + Issuer ID).

---

## 1. BLOCKER — rename the package

Right now both platforms use `com.example.autonect`:

- `android/app/build.gradle.kts` → `namespace` and `applicationId`
- `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER`

**Google Play rejects any `com.example.*` package**, and Apple will not take it
either, so the app cannot be uploaded as it stands.

It is also **permanent once published**, and these all key off it:
- the Firebase `google-services.json` (issued per package name)
- the RevenueCat app and the Play products
- the backend's Play "manage subscription" deep link

What to change:
1. `namespace` and `applicationId` in `android/app/build.gradle.kts`.
2. The Kotlin folder `android/app/src/main/kotlin/com/example/autonect/` and the
   `package` line in `MainActivity.kt`.
3. `PRODUCT_BUNDLE_IDENTIFIER` for `Runner` and `RunnerTests` in Xcode.
4. `flutter clean && flutter pub get`, then rebuild.

**Tell us the final name** — the backend has it in an environment variable
(`ANDROID_PACKAGE_NAME`) and we update it on our side.

## 2. BLOCKER — real signing key

`android/app/build.gradle.kts` currently signs release builds with the debug
key:

```kotlin
release {
    // TODO: Add your own signing config for the release build.
    signingConfig = signingConfigs.getByName("debug")
}
```

Play refuses debug-signed uploads, and in-app purchases only work on a build
signed with the key Play knows. Create an upload key:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload
```

Then `android/key.properties` (**never committed**):

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=../upload-keystore.jks
```

…and wire it in `build.gradle.kts` the standard Flutter way, replacing the
debug line above.

Add to `.gitignore`:

```
android/key.properties
**/*.jks
**/*.keystore
```

> Back the keystore up somewhere safe. Losing it means the app can never be
> updated again under the same listing.

## 3. Upload to Play internal testing

Products cannot be created in Play Console until a build has been uploaded,
and purchases only work for builds **installed from Play** — a local
`flutter run` build can never complete a purchase.

So: signed AAB → internal testing track → add the testers the client names as
**licence testers** (Play Console → Setup → Licence testing) so purchases are
free to test.

## 4. Push notifications — not started in the app

Nothing push-related exists in the app yet: no `firebase_core`, no
`firebase_messaging`, no `google-services.json`, no token registration.

The backend side is done and live. **`PUSH-NOTIFICATIONS.md`** in this repo has
the full guide — endpoints, the payload table, the code sketch and
troubleshooting. The short version:

1. Add `firebase_core`, `firebase_messaging`, `flutter_local_notifications`.
2. Drop in `google-services.json` for the **final** package name (ask the
   client; Firebase project is `autonect1`).
3. Create the Android notification channel with id **exactly**
   `autonect_default` — any other id and notifications arrive silently.
4. Register the token after login (`POST /v1/devices/token`), delete it on
   logout (`DELETE /v1/devices/token`).
5. Route taps on `data.type` (`chat`, `booking`, `request`, `offer`, `order`,
   `billing`, `kyc`, `review`); anything unknown opens the notification centre.
6. Verify with `POST /v1/devices/token/test` — it pushes only to your own
   devices.

## 5. Billing — the app code is already done

`purchases_flutter` is integrated: offerings, purchase, restore, the plans
screens, and store deep links for cancel/resume. **No app code is needed.**

What makes it work is outside the app:
- the client creates the products in Play Console with these exact ids:

  | Product ID | Type | Price |
  |---|---|---|
  | `autonect_electrician_pro_monthly` | subscription, monthly | £149.00 |
  | `autonect_supplier_unlimited_monthly` | subscription, monthly | £299.00 |
  | `autonect_electrician_leads_1` | consumable | £12.00 |
  | `autonect_electrician_leads_5` | consumable | £55.00 |
  | `autonect_electrician_leads_10` | consumable | £100.00 |
  | `autonect_supplier_credits_10` | consumable | £10.00 |

- the client sets up RevenueCat (entitlement `pro`, offering `default`) and
  sends us the API keys;
- **you** provide the Play service account JSON so RevenueCat can verify
  purchases.

Prices must match the table — the app shows our price and the store charges
its own, so a mismatch means showing one price and billing another.

Note: cancelling, resuming and changing a card all happen **in the store**.
The app links out to it; that is deliberate, not a missing feature.

## 6. iOS, when it starts

- Bundle id set to the final name, with a matching App ID in the Apple account.
- `GoogleService-Info.plist` from the `autonect1` Firebase project.
- **APNs auth key (`.p8`)** uploaded to Firebase → Cloud Messaging, or iOS push
  silently never arrives.
- Push Notifications + Background Modes capabilities.
- The same six products in App Store Connect, plus an **in-app purchase key**
  (`.p8`, Key ID, Issuer ID) for RevenueCat.

## 7. Done when

- [ ] Package renamed on both platforms; name sent to us.
- [ ] Upload keystore created, wired, backed up; `key.properties` not committed.
- [ ] Signed build on a Play internal testing track.
- [ ] SHA-1/SHA-256 sent, Firebase registered, `google-services.json` in place.
- [ ] Push: permission, token registration, logout removal, tap routing.
- [ ] `POST /v1/devices/token/test` buzzes the phone.
- [ ] Play service account JSON handed over for RevenueCat.
- [ ] A test purchase with a licence tester completes and the plan appears in
      the app (we can confirm from the server side).
