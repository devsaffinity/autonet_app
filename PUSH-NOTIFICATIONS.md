# Push notifications — what the app must do

**Written for: the Flutter app developer.** The backend half is finished and
live-ready: it stores device tokens, decides who gets what, and sends through
Firebase Cloud Messaging. What is left is the app: ask for permission, send us
the token, show the notification, and open the right screen when it is tapped.

Firebase project: **autonect1**. The server already holds the service account.

---

## 1. What the server gives you

### Register a device (after every login, and whenever the token changes)

```http
POST /v1/devices/token
Authorization: Bearer <access token>
{ "fcmToken": "<FCM registration token>", "platform": "ANDROID" }   // or "IOS"
```

A token belongs to ONE account: registering it again under a different user
moves it, so the previous user stops receiving that phone's pushes. That is
what makes a shared device behave on logout/login.

### Remove a device (on logout — do this before clearing the session)

```http
DELETE /v1/devices/token
{ "fcmToken": "<same token>" }
```

If you skip this, the person who logs in next keeps getting the old user's
notifications until they log in again.

### Send yourself a test push (your wiring check)

```http
POST /v1/devices/token/test
→ { "sent": 2, "removed": 0, "devices": 2 }
```

It only ever reaches the calling account's own devices. `sent` is how many
devices FCM accepted it for — `0` means we have no token for you, so step 1
has not worked. Limited to 3 per minute.

### The in-app notification centre (already working)

| Method | Path | Purpose |
|---|---|---|
| GET | `/v1/notifications?page=1&limit=20` | list, newest first |
| PATCH | `/v1/notifications/:id/read` | mark one read |
| POST | `/v1/notifications/read-all` | mark all read |
| DELETE | `/v1/notifications/:id` | delete one |
| DELETE | `/v1/notifications` | clear all |

Push and the notification centre are separate deliveries of the same event.
Do not create a local notification row when a push arrives — the server has
already stored it.

---

## 2. What a push looks like

Every message carries both a `notification` block (so the OS can display it
while the app is closed) and a `data` block (so you can route the tap).

```jsonc
{
  "notification": { "title": "New booking request", "body": "Jack booked you for Tuesday 10:00" },
  "data": {
    "type": "booking",                    // the screen to open
    "event": "booking.created",           // the exact domain event
    "bookingId": "0f1c…",                 // the id for that screen
    "title": "New booking request",       // repeated: Android drops `notification` in foreground
    "body": "Jack booked you for Tuesday 10:00"
  }
}
```

**`data.type` is what you route on.** Everything in `data` is a string — FCM
cannot carry anything else.

| `data.type` | Also carries | Open |
|---|---|---|
| `chat` | `conversationId`, sometimes `bookingId` | that chat thread |
| `booking` | `bookingId`, sometimes `status` | booking details |
| `request` | `requestId` | the part request |
| `offer` | `requestId`, `offerId` | offers for that request |
| `order` | `orderId`, sometimes `status` | order details |
| `billing` | — | Plans & Billing |
| `kyc` | sometimes `userId` | KYC / verification status |
| `review` | `reviewId` | the review |
| `account` | — | account status (a suspension) |
| `test` | — | nothing; it is the wiring check |

If `type` is missing or unknown, open the notification centre. Never crash on
an unexpected value — new event types ship without an app release.

---

## 3. Android

The server sends every push on channel id **`autonect_default`** with high
priority. **You must create a channel with exactly that id**, otherwise
Android 8+ shows the notification silently with no heads-up banner.

```dart
const channel = AndroidNotificationChannel(
  'autonect_default',              // MUST match the server
  'Autonect',
  description: 'Bookings, messages, orders and billing',
  importance: Importance.high,
);
await FlutterLocalNotificationsPlugin()
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
```

Also needed:
- `android/app/google-services.json` from the **autonect1** Firebase project
  (ask for it; it is not in the repo), and the Google services Gradle plugin.
- Android 13+: request the `POST_NOTIFICATIONS` runtime permission, and expect
  people to say no.
- The tap intent is `FLUTTER_NOTIFICATION_CLICK`, which `firebase_messaging`
  handles for you.

## 4. iOS (when it ships)

- `GoogleService-Info.plist` from the same Firebase project.
- Push Notifications + Background Modes (remote notifications) capabilities.
- An **APNs auth key (.p8)** uploaded to Firebase → Project settings → Cloud
  Messaging. Without it iOS pushes silently never arrive.
- The server sets `sound: default` and a **badge** equal to the user's unread
  count, so the icon badge stays correct without you computing it.

---

## 5. The flow to implement

```dart
// 1. permission (iOS always, Android 13+)
final settings = await FirebaseMessaging.instance.requestPermission();

// 2. token -> our API, after login
final token = await FirebaseMessaging.instance.getToken();
if (token != null) await api.registerDevice(token, platform);

// 3. the token rotates on its own — re-register when it does
FirebaseMessaging.instance.onTokenRefresh.listen(api.registerDevice);

// 4. foreground: Android shows nothing by itself, so draw it yourself
FirebaseMessaging.onMessage.listen((m) => showLocalNotification(m));

// 5. tapped from background / terminated
FirebaseMessaging.onMessageOpenedApp.listen(handleTap);
final initial = await FirebaseMessaging.instance.getInitialMessage();
if (initial != null) handleTap(initial);        // app was launched by the tap

// 6. logout
await api.removeDevice(token);
await FirebaseMessaging.instance.deleteToken();
```

`handleTap` reads `message.data['type']` and pushes the matching route, using
the id in the same map.

---

## 6. Checklist before calling it done

- [ ] Permission asked, and refusing it does not break anything.
- [ ] Token registered after login and re-registered on refresh.
- [ ] `POST /v1/devices/token/test` returns `sent: 1` and the phone buzzes.
- [ ] Foreground, background and terminated all show the notification.
- [ ] Tapping opens the right screen for each `type` in the table above.
- [ ] Logout removes the token; the next account gets no stray notifications.
- [ ] Android heads-up banner appears (proves the channel id matches).
- [ ] Unknown `type` falls back to the notification centre.

## 7. When it does not arrive

| Symptom | Usual cause |
|---|---|
| `sent: 0` from the test endpoint | the token never reached us — check step 2 |
| Nothing on the device, `sent: 1` | wrong Firebase project, or app killed by the OEM battery manager |
| Arrives silently, no banner (Android) | channel id is not `autonect_default` |
| Works in debug, not release (Android) | release build not signed with the SHA registered in Firebase |
| Nothing on iOS | APNs .p8 key missing in Firebase, or testing on a simulator |
| Stops after a reinstall | expected: the token changes, re-register on next login |
