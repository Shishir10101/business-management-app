import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';

/// Theme mode provider: light/dark/system
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});
