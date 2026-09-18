package com.example.autonect

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, not FlutterActivity: Stripe's payment sheet is
// shown through the AndroidX fragment manager and fails without it.
class MainActivity : FlutterFragmentActivity()
