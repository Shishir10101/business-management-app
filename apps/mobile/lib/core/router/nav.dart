import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// Navigates to [path], choosing between replacing and stacking.
///
/// The app used to call `context.go` for every navigation, which *replaces*
/// the whole stack. The practical effect on a phone was that no screen ever
/// had a back button and Android's back gesture left the app instead of
/// returning to the list — every page was a dead end whose only exit was the
/// browser's back button.
///
/// Tab roots still replace (the bottom bar is the navigation), everything else
/// pushes so the screen you came from stays one tap away.
void openRoute(BuildContext context, String path) {
  if (tabRoots.contains(path)) {
    context.go(path);
  } else {
    // The returned future completes when the pushed screen pops; no caller in
    // this app needs the result.
    context.push(path);
  }
}
