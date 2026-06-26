import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Standard page-to-page navigation.
/// iOS: CupertinoPageRoute — horizontal slide + interactive swipe-back gesture.
/// Android: MaterialPageRoute — native Android transition.
PageRoute<T> slideRoute<T>({required WidgetBuilder builder}) {
  if (Platform.isIOS) {
    return CupertinoPageRoute<T>(builder: builder);
  }
  return MaterialPageRoute<T>(builder: builder);
}

/// Fullscreen modal navigation (slides in from the bottom).
/// iOS: CupertinoPageRoute(fullscreenDialog: true) — swipe-down-to-dismiss.
/// Android: MaterialPageRoute(fullscreenDialog: true).
PageRoute<T> modalRoute<T>({required WidgetBuilder builder}) {
  if (Platform.isIOS) {
    return CupertinoPageRoute<T>(builder: builder, fullscreenDialog: true);
  }
  return MaterialPageRoute<T>(builder: builder, fullscreenDialog: true);
}
