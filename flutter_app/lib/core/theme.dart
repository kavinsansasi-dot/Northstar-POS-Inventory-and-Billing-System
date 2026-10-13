import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color brandIndigo = Color(0xFF4F46E5);
const Color brandEmerald = Color(0xFF10B981);
const Color brandAmber = Color(0xFFF59E0B);
const Color brandRose = Color(0xFFF43F5E);
const Color brandIndigoSoft = Color(0xFFEEF2FF);

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadii {
  static const double input = 12;
  static const double button = 12;
  static const double card = 16;
  static const double pill = 999;
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primarySoft,
    required this.accent,
    required this.warning,
    required this.danger,
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.shadow,
    this.brandGradientStart = const Color(0xFF312E81),
    this.brandGradientEnd = brandIndigo,
    this.brandAccentLight = const Color(0xFFA5B4FC),
    this.brandOnPrimary = const Color(0xFFFFFFFF),
  });

  final Color primary;
  final Color primarySoft;
  final Color accent;
  final Color warning;
  final Color danger;
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color shadow;
  final Color brandGradientStart;
  final Color brandGradientEnd;
  final Color brandAccentLight;
  final Color brandOnPrimary;

  static const light = AppPalette(
    primary: brandIndigo,
    primarySoft: brandIndigoSoft,
    accent: brandEmerald,
    warning: brandAmber,
    danger: brandRose,
    background: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    shadow: Color(0x0F111827),
    brandGradientStart: Color(0xFF312E81),
    brandGradientEnd: Color(0xFF4F46E5),
    brandAccentLight: Color(0xFFA5B4FC),
    brandOnPrimary: Color(0xFFFFFFFF),
  );

  static const dark = AppPalette(
    primary: brandIndigo,
    primarySoft: Color(0xFF24234A),
    accent: brandEmerald,
    warning: brandAmber,
    danger: brandRose,
    background: Color(0xFF0B0F1A),
    surface: Color(0xFF121826),
    border: Color(0xFF1F2937),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    shadow: Color(0x66000000),
    brandGradientStart: Color(0xFF312E81),
    brandGradientEnd: Color(0xFF4F46E5),
    brandAccentLight: Color(0xFFA5B4FC),
    brandOnPrimary: Color(0xFFFFFFFF),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primarySoft,
    Color? accent,
    Color? warning,
    Color? danger,
    Color? background,
    Color? surface,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? shadow,
    Color? brandGradientStart,
    Color? brandGradientEnd,
    Color? brandAccentLight,
    Color? brandOnPrimary,
  }) => AppPalette(
    primary: primary ?? this.primary,
    primarySoft: primarySoft ?? this.primarySoft,
    accent: accent ?? this.accent,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    border: border ?? this.border,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    shadow: shadow ?? this.shadow,
    brandGradientStart: brandGradientStart ?? this.brandGradientStart,
    brandGradientEnd: brandGradientEnd ?? this.brandGradientEnd,
    brandAccentLight: brandAccentLight ?? this.brandAccentLight,
    brandOnPrimary: brandOnPrimary ?? this.brandOnPrimary,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      brandGradientStart:
          Color.lerp(brandGradientStart, other.brandGradientStart, t)!,
      brandGradientEnd:
          Color.lerp(brandGradientEnd, other.brandGradientEnd, t)!,
      brandAccentLight:
          Color.lerp(brandAccentLight, other.brandAccentLight, t)!,
      brandOnPrimary: Color.lerp(brandOnPrimary, other.brandOnPrimary, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

ThemeData buildAppTheme(Brightness brightness) {
  final palette = brightness == Brightness.light
      ? AppPalette.light
      : AppPalette.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: palette.primary,
    brightness: brightness,
    surface: palette.surface,
    primary: palette.primary,
    secondary: palette.accent,
    error: palette.danger,
  );
  final bodyTheme = GoogleFonts.interTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );
  final headingTheme = GoogleFonts.plusJakartaSansTextTheme(bodyTheme);
  final textTheme = TextTheme(
    displayLarge: _figures(headingTheme.displayLarge?.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: palette.textPrimary,
    )),
    displayMedium: _figures(headingTheme.displayMedium?.copyWith(
      color: palette.textPrimary,
    )),
    displaySmall: _figures(headingTheme.displaySmall?.copyWith(
      color: palette.textPrimary,
    )),
    headlineLarge: _figures(headingTheme.headlineLarge?.copyWith(
      color: palette.textPrimary,
    )),
    headlineMedium: _figures(headingTheme.headlineMedium?.copyWith(
      color: palette.textPrimary,
    )),
    headlineSmall: _figures(headingTheme.headlineSmall?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: palette.textPrimary,
    )),
    titleLarge: _figures(headingTheme.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: palette.textPrimary,
    )),
    titleMedium: _figures(headingTheme.titleMedium?.copyWith(
      color: palette.textPrimary,
    )),
    titleSmall: _figures(headingTheme.titleSmall?.copyWith(
      color: palette.textPrimary,
    )),
    bodyLarge: _figures(bodyTheme.bodyLarge?.copyWith(
      color: palette.textPrimary,
    )),
    bodyMedium: _figures(bodyTheme.bodyMedium?.copyWith(
      fontSize: 14,
      color: palette.textPrimary,
    )),
    bodySmall: _figures(bodyTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: palette.textSecondary,
    )),
    labelLarge: _figures(bodyTheme.labelLarge?.copyWith(
      color: palette.textPrimary,
    )),
    labelMedium: _figures(bodyTheme.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: palette.textSecondary,
    )),
    labelSmall: _figures(bodyTheme.labelSmall?.copyWith(
      color: palette.textSecondary,
    )),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.background,
    extensions: [palette],
    textTheme: textTheme,
    dividerColor: palette.border,
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      elevation: 0,
      color: palette.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: palette.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: TextStyle(color: palette.textSecondary),
      labelStyle: TextStyle(color: palette.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: palette.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: palette.danger, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.textPrimary,
        side: BorderSide(color: palette.border),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: brightness == Brightness.light
          ? const Color(0xFF111827)
          : const Color(0xFFE5E7EB),
      contentTextStyle: TextStyle(
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF111827),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

TextStyle? _figures(TextStyle? style) => style?.copyWith(
  fontFeatures: const [FontFeature.tabularFigures()],
);

class ThemeModeController extends ChangeNotifier {
  ThemeModeController() {
    _restore();
  }

  static const _preferenceKey = 'pos_dark_mode';
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    _mode = preferences.getBool(_preferenceKey) == true
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, _mode == ThemeMode.dark);
  }
}

class ThemeModeScope extends InheritedWidget {
  const ThemeModeScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final ThemeModeController controller;

  static ThemeModeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeModeScope>()?.controller;

  @override
  bool updateShouldNotify(ThemeModeScope oldWidget) =>
      controller != oldWidget.controller;
}
