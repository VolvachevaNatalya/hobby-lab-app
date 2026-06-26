import 'package:flutter/cupertino.dart';

/// Standard page-to-page navigation.
/// Horizontal slide on both platforms; iOS also gets the interactive swipe-back
/// gesture. Uses CupertinoPageRoute on Android to avoid MaterialPageRoute's
/// predictive-back integration (ZoomPageTransitionsBuilder / OnBackInvokedCallback)
/// which interferes with the standard Android back button when
/// android:enableOnBackInvokedCallback is not set in the manifest.
PageRoute<T> slideRoute<T>({required WidgetBuilder builder}) =>
    CupertinoPageRoute<T>(builder: builder);

/// Fullscreen modal navigation (slides in from the bottom).
/// iOS: swipe-down-to-dismiss. Android: back button works via standard mechanism.
PageRoute<T> modalRoute<T>({required WidgetBuilder builder}) =>
    CupertinoPageRoute<T>(builder: builder, fullscreenDialog: true);
