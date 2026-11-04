import 'package:flutter/material.dart';

/// EdTech Ecosystem design system — warm coral-orange brand with deep
/// readability. Every colour, spacing and type scale is defined here so the
/// whole app feels cohesive on every screen size.

const kPrimary = Color(0xFFFF7A3D); // sharp coral orange
const kPrimaryDark = Color(0xFFE8601C); // deep burnt orange
const kAccent = Color(0xFFFFB347); // sunny tangerine
const kAccentDark = Color(0xFFCC7A00);

const kSurface = Color(0xFFFFFFFF);
const kBackground = Color(0xFFFFF7F2); // softer peach, kind on the eyes
const kCard = Color(0xFFFFFFFF);

const kTextPrimary = Color(0xFF1F2937); // near-black espresso for headings
const kTextBody = Color(0xFF374151); // body text — highly readable
const kTextSecondary = Color(0xFF6B7280); // warm taupe for captions / hints
const kTextInverse = Colors.white;

const kBorder = Color(0xFFE5E0D6);
const kDivider = Color(0xFFF2EBDF);

const kSuccess = Color(0xFF10B981);
const kSuccessBg = Color(0xFFECFDF5);
const kWarning = Color(0xFFF59E0B);
const kWarningBg = Color(0xFFFFFBEB);
const kError = Color(0xFFEF4444);
const kErrorBg = Color(0xFFFEF2F2);

const kPink = Color(0xFFEC4899);
const kPurple = Color(0xFBA3C3);
const kBlue = Color(0xBFDBFE);
const kOrange = Color(0xFFFF7A3D);

/// Spacing scale — use these instead of raw numbers everywhere.
const kSpaceXs = 6.0;
const kSpaceSm = 10.0;
const kSpaceMd = 16.0;
const kSpaceLg = 24.0;
const kSpaceXl = 32.0;
const kSpaceXxl = 40.0;

/// Border radius scale.
const kRadiusSm = 12.0;
const kRadiusMd = 20.0;
const kRadiusLg = 28.0;
const kRadiusXl = 40.0;

/// Elevation scale (soft shadows only).
const kShadowSm = BoxShadow(
  color: Color(0x0F000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);
const kShadowMd = BoxShadow(
  color: Color(0x14000000),
  blurRadius: 16,
  offset: Offset(0, 6),
);
const kShadowLg = BoxShadow(
  color: Color(0x1E000000),
  blurRadius: 24,
  offset: Offset(0, 10),
);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.light,
  ).copyWith(
    primary: kPrimary,
    secondary: kBlue,
    surface: kSurface,
    background: kBackground,
    onPrimary: Colors.white,
    onSurface: kTextPrimary,
    onSecondary: Colors.white,
  ),
  scaffoldBackgroundColor: kBackground,
  cardTheme: CardThemeData(
    elevation: 0,
    color: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLg)),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: kTextPrimary,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: kTextPrimary,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: kSpaceMd, vertical: kSpaceMd),
    hintStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadiusMd),
      borderSide: BorderSide(color: kBorder, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadiusMd),
      borderSide: BorderSide(color: kBorder, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadiusMd),
      borderSide: BorderSide(color: kPrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadiusMd),
      borderSide: BorderSide(color: kError, width: 1),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: kSpaceLg, vertical: kSpaceMd),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: kSpaceMd, vertical: kSpaceSm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kPrimary,
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: kTextPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 14,
    ),
  ),
  dividerTheme: const DividerThemeData(color: kDivider, space: 2),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: kTextPrimary, height: 1.1),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kTextPrimary, height: 1.15),
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary, height: 1.2),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextPrimary, height: 1.25),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary, height: 1.3),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary, height: 1.4),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary, height: 1.4),
    titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextPrimary, height: 1.5),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTextBody, height: 1.6),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextBody, height: 1.6),
    bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextBody, height: 1.6),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary, height: 1.4),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary, height: 1.5),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextSecondary, height: 1.5),
  ),
);

/// Signature hero gradient — sharp orange to deep burnt orange.
const candyGradient = LinearGradient(
  colors: [kPrimary, kPrimaryDark],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Playful gradient used on hero cards, floating chips, and active nav tabs.
LinearGradient livelyGradient(Color start, Color end) => LinearGradient(
  colors: [start, end],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Soft pastel tint for subtle background chips (per accent colour).
tintOf(Color color, [double opacity = 0.10]) => color.withValues(alpha: opacity);

/// Darkens [color] toward black by [amount] (0..1).
Color shadeOf(Color color, [double amount = 0.15]) => Color.lerp(color, Colors.black, amount)!;

/// Per-tab accent colours used across nav, cards, and chips.
const kTabColors = <Color>[
  kPrimary, // Dashboard
  kBlue, // Courses
  kPink, // Calendar
  kAccent, // Chat
  kSuccess, // Integrity
  kPurple, // Students
  kOrange, // Departments
  kWarning, // Attendance
  kPink, // Notes
];

/// Helper: read text styles cleanly.
extension TextScale on BuildContext {
  TextStyle get h1 => Theme.of(this).textTheme.displayMedium!;
  TextStyle get h2 => Theme.of(this).textTheme.headlineLarge!;
  TextStyle get h3 => Theme.of(this).textTheme.headlineMedium!;
  TextStyle get h4 => Theme.of(this).textTheme.headlineSmall!;
  TextStyle get h5 => Theme.of(this).textTheme.titleLarge!;
  TextStyle get subtitle1 => Theme.of(this).textTheme.titleMedium!;
  TextStyle get subtitle2 => Theme.of(this).textTheme.titleSmall!;
  TextStyle get body1 => Theme.of(this).textTheme.bodyLarge!;
  TextStyle get body2 => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get caption => Theme.of(this).textTheme.labelMedium!;
  TextStyle get overline => Theme.of(this).textTheme.labelSmall!;
}

/// Helper: card shadow.
BoxShadow cardShadow(Color color) => BoxShadow(
  color: color.withValues(alpha: 0.12),
  blurRadius: 20,
  offset: const Offset(0, 8),
);

/// Helper: icon bubble gradient decoration.
Decoration iconBubble(Color color) => BoxDecoration(
  gradient: livelyGradient(color, shadeOf(color, 0.15)),
  borderRadius: BorderRadius.circular(kRadiusMd),
  boxShadow: [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 12,
      offset: const Offset(0, 5),
    ),
  ],
);
