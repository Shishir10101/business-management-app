import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// Semantic money colours.
///
/// Every screen used to pick its own shade (`Colors.blue.shade700` for
/// "to collect", `Colors.orange.shade800` for "to pay", `colorScheme.error`
/// for a customer's balance) so the same fact wore three different colours in
/// three places. A shopkeeper reads a colour before reading a number, so the
/// direction of money has to be one decision made once:
///
/// * [positive] — money coming in: sales, receivable, profit.
/// * [negative] — money going out: payable, expense, loss.
/// * [warning] — needs a look: low stock, overdue reminder.
/// * [neutral] — settled, zero balance, no action.
///
/// Each has a matching low-saturation [positiveTint] etc. for chip and row
/// backgrounds, so a tinted row stays readable in both themes.
@immutable
class MoneyColors extends ThemeExtension<MoneyColors> {
  final Color positive;
  final Color negative;
  final Color warning;
  final Color neutral;
  final Color positiveTint;
  final Color negativeTint;
  final Color warningTint;

  const MoneyColors({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.neutral,
    required this.positiveTint,
    required this.negativeTint,
    required this.warningTint,
  });

  static const light = MoneyColors(
    positive: Color(0xFF0B6E4F),
    negative: Color(0xFFB3261E),
    warning: Color(0xFF9A6400),
    neutral: Color(0xFF6B7280),
    positiveTint: Color(0xFFE3F2EA),
    negativeTint: Color(0xFFFCE9E7),
    warningTint: Color(0xFFFBF0DA),
  );

  /// Lifted lightness for dark surfaces: the light values fail contrast on a
  /// near-black card.
  static const dark = MoneyColors(
    positive: Color(0xFF3DDC97),
    negative: Color(0xFFFF8A7A),
    warning: Color(0xFFFFC15E),
    neutral: Color(0xFF9AA5A0),
    positiveTint: Color(0xFF17322A),
    negativeTint: Color(0xFF3A211F),
    warningTint: Color(0xFF3A2E1A),
  );

  @override
  MoneyColors copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
    Color? neutral,
    Color? positiveTint,
    Color? negativeTint,
    Color? warningTint,
  }) {
    return MoneyColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      neutral: neutral ?? this.neutral,
      positiveTint: positiveTint ?? this.positiveTint,
      negativeTint: negativeTint ?? this.negativeTint,
      warningTint: warningTint ?? this.warningTint,
    );
  }

  @override
  MoneyColors lerp(ThemeExtension<MoneyColors>? other, double t) {
    if (other is! MoneyColors) return this;
    return MoneyColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      positiveTint: Color.lerp(positiveTint, other.positiveTint, t)!,
      negativeTint: Color.lerp(negativeTint, other.negativeTint, t)!,
      warningTint: Color.lerp(warningTint, other.warningTint, t)!,
    );
  }
}

/// Shorthand for `Theme.of(context).extension<MoneyColors>()`.
extension MoneyColorsX on BuildContext {
  MoneyColors get money =>
      Theme.of(this).extension<MoneyColors>() ?? MoneyColors.light;
}

/// The app's visual language.
///
/// Modelled on what shopkeepers already use — Khatabook, Vyapar and the local
/// Khata apps — rather than on a generic Material demo: a deep money-green
/// brand, warm paper background, soft white cards with a hairline border
/// (not heavy shadows, which read as clutter on a cheap phone in daylight),
/// and a single amber accent reserved for "money out / attention".
class AppTheme {
  // Brand.
  static const _primaryColor = Color(0xFF0B6E4F); // deep emerald
  static const _primaryColorDark = Color(0xFF3DDC97); // readable on dark
  static const _accentColor = Color(0xFFE8A33D); // amber

  // Surfaces.
  static const _paper = Color(0xFFF7F5F1); // warm off-white
  static const _cardBorder = Color(0xFFE6E1D8);
  static const _fieldFill = Color(0xFFF3F0EA);

  static const _darkSurface = Color(0xFF161A18);
  static const _darkCard = Color(0xFF1E2422);
  static const _darkField = Color(0xFF262D2A);

  /// Money is read in columns — a list of balances, a report table — so every
  /// amount uses tabular figures. Without it "Rs. 1,111.00" and "Rs. 9,999.00"
  /// are different widths and the right edge of the column wobbles.
  static const tabularFigures = [FontFeature.tabularFigures()];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      secondary: _accentColor,
      surface: Colors.white,
    );

    return _base(
      scheme: scheme,
      money: MoneyColors.light,
      background: _paper,
      cardColor: Colors.white,
      cardBorder: _cardBorder,
      fieldFill: _fieldFill,
      appBarBackground: _primaryColor,
      appBarForeground: Colors.white,
      snackBackground: const Color(0xFF232B28),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primaryColorDark,
      brightness: Brightness.dark,
      secondary: _accentColor,
      surface: _darkSurface,
    );

    return _base(
      scheme: scheme,
      money: MoneyColors.dark,
      background: const Color(0xFF0F1312),
      cardColor: _darkCard,
      cardBorder: const Color(0xFF2C3431),
      fieldFill: _darkField,
      appBarBackground: _darkSurface,
      appBarForeground: scheme.onSurface,
      snackBackground: _darkField,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required MoneyColors money,
    required Color background,
    required Color cardColor,
    required Color cardBorder,
    required Color fieldFill,
    required Color appBarBackground,
    required Color appBarForeground,
    required Color snackBackground,
  }) {
    final radius = BorderRadius.circular(16);
    final fieldRadius = BorderRadius.circular(12);
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: [money],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: appBarForeground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        // A 1px lift is not visible as a shadow but stops a white card from
        // dissolving into the paper background on a dim screen — the reason
        // every khata app's cards read as raised without looking heavy.
        elevation: isDark ? 0 : 1,
        shadowColor: isDark ? Colors.transparent : const Color(0x14000000),
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: cardBorder),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: scheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      // The primary action on every list screen. It used to inherit the
      // Material default (a pale tonal surface), which on the cream background
      // read as a disabled control rather than the main thing to tap.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        highlightElevation: 6,
        extendedTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: cardBorder),
      ),
      dividerTheme: DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // The bottom bar is the app's main navigation now. Flat white with a
      // hairline top border and a soft primary pill behind the active icon —
      // the pattern Khatabook and Vyapar both use, and the one a shopkeeper's
      // thumb already knows.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 66,
        indicatorColor: scheme.primary.withOpacity(isDark ? 0.24 : 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
