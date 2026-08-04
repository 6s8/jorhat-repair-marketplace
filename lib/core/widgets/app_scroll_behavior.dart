import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A custom [ScrollBehavior] that enables the StretchingOverscrollIndicator
/// for touch/drag interactions. Mouse wheel overscroll is handled by the browser
/// on Flutter Web and cannot be intercepted at the Flutter layer.
///
/// To see the stretch effect in Chrome: click-and-drag the list content past
/// the end (like you would on a phone). Mouse-wheel scroll does NOT trigger it.
class AppStretchScrollBehavior extends MaterialScrollBehavior {
  const AppStretchScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}
