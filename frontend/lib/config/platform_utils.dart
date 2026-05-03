// Platform detection utilities that work on all platforms (including web).
//
// On web, `dart:io` is unavailable so we cannot use `Platform.isAndroid`.
// This file provides a safe abstraction using `kIsWeb` from foundation.
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

/// Returns true if the app is running on an Android device/emulator.
/// Always returns false on web, regardless of the host OS.
bool get isAndroidPlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android;
}
