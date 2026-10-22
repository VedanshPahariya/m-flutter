import 'package:flutter/material.dart';

/// Semantic colours from the prototype's design tokens (`--k-*`).
@immutable
class KoraColors extends ThemeExtension<KoraColors> {
  const KoraColors({
    required this.base,
    required this.raised,
    required this.sunken,
    required this.line,
    required this.control,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.mute,
    required this.accent,
    required this.accentContainer,
    required this.accentSelected,
    required this.danger,
    required this.warn,
    required this.ok,
    required this.violet,
    required this.warnContainer,
    required this.warnInk,
    required this.track,
  });

  final Color base;
  final Color raised;
  final Color sunken;
  final Color line;
  final Color control;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color mute;
  final Color accent;
  final Color accentContainer;
  final Color accentSelected;
  final Color danger;
  final Color warn;
  final Color ok;
  final Color violet;
  final Color warnContainer;
  final Color warnInk;
  final Color track;

  static const light = KoraColors(
    base: Color(0xFFFAF9F7),
    raised: Color(0xFFFFFFFF),
    sunken: Color(0xFFEFEDE8),
    line: Color(0xFFE6E3DD),
    control: Color(0xFFD4D0C8),
    ink: Color(0xFF1C1B19),
    ink2: Color(0xFF3A3834),
    ink3: Color(0xFF55524C),
    mute: Color(0xFF75716A),
    accent: Color(0xFF155E63),
    accentContainer: Color(0xFFDCEBEA),
    accentSelected: Color(0xFFEEF4F3),
    danger: Color(0xFFB3362B),
    warn: Color(0xFFC27A12),
    ok: Color(0xFF2F7D4F),
    violet: Color(0xFF6A4FB3),
    warnContainer: Color(0xFFFBEFD9),
    warnInk: Color(0xFF8A5A0E),
    track: Color(0xFFF0EEEA),
  );

  static const dark = KoraColors(
    base: Color(0xFF141412),
    raised: Color(0xFF1E1D1B),
    sunken: Color(0xFF2A2926),
    line: Color(0xFF2E2D2A),
    control: Color(0xFF4A4844),
    ink: Color(0xFFECEAE5),
    ink2: Color(0xFFCFCBC4),
    ink3: Color(0xFFAEAAA2),
    mute: Color(0xFF928E86),
    accent: Color(0xFF6FB5B0),
    accentContainer: Color(0xFF1F3A3B),
    accentSelected: Color(0xFF1A2C2D),
    danger: Color(0xFFEF7A6E),
    warn: Color(0xFFE0A54A),
    ok: Color(0xFF6CC28F),
    violet: Color(0xFFA893E6),
    warnContainer: Color(0xFF3A2E17),
    warnInk: Color(0xFFE8B866),
    track: Color(0xFF2A2926),
  );

  @override
  KoraColors copyWith() => this;

  @override
  KoraColors lerp(ThemeExtension<KoraColors>? other, double t) {
    if (other is! KoraColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return KoraColors(
      base: l(base, other.base),
      raised: l(raised, other.raised),
      sunken: l(sunken, other.sunken),
      line: l(line, other.line),
      control: l(control, other.control),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      ink3: l(ink3, other.ink3),
      mute: l(mute, other.mute),
      accent: l(accent, other.accent),
      accentContainer: l(accentContainer, other.accentContainer),
      accentSelected: l(accentSelected, other.accentSelected),
      danger: l(danger, other.danger),
      warn: l(warn, other.warn),
      ok: l(ok, other.ok),
      violet: l(violet, other.violet),
      warnContainer: l(warnContainer, other.warnContainer),
      warnInk: l(warnInk, other.warnInk),
      track: l(track, other.track),
    );
  }
}

extension KoraThemeX on BuildContext {
  KoraColors get kora => Theme.of(this).extension<KoraColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(KoraColors.light, Brightness.light);
  static ThemeData dark() => _build(KoraColors.dark, Brightness.dark);

  static ThemeData _build(KoraColors k, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: k.accent,
      onPrimary: brightness == Brightness.light ? Colors.white : k.base,
      primaryContainer: k.accentContainer,
      onPrimaryContainer: k.ink,
      secondary: k.ink2,
      onSecondary: k.base,
      error: k.danger,
      onError: Colors.white,
      surface: k.base,
      onSurface: k.ink,
      onSurfaceVariant: k.ink3,
      surfaceContainerLowest: k.raised,
      surfaceContainerLow: k.raised,
      surfaceContainer: k.raised,
      surfaceContainerHigh: k.sunken,
      surfaceContainerHighest: k.sunken,
      outline: k.control,
      outlineVariant: k.line,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: k.base,
      extensions: [k],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    final text = base.textTheme.apply(bodyColor: k.ink, displayColor: k.ink);
    return base.copyWith(
      textTheme: text.copyWith(
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: k.base,
        foregroundColor: k.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: k.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: k.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: k.line, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: k.raised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: k.control),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: k.control),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: k.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: k.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 46),
          foregroundColor: k.ink,
          side: BorderSide(color: k.control),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: k.raised,
        selectedColor: k.ink,
        side: BorderSide(color: k.line),
        labelStyle: TextStyle(color: k.ink, fontWeight: FontWeight.w500),
        secondaryLabelStyle: TextStyle(color: k.base),
        checkmarkColor: k.base,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: k.raised,
        indicatorColor: k.accentContainer,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, color: k.ink2, fontWeight: FontWeight.w500),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: k.raised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: k.ink,
        contentTextStyle: TextStyle(color: k.base),
        actionTextColor: brightness == Brightness.light
            ? const Color(0xFF9FD3CF)
            : const Color(0xFF155E63),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: k.ink3,
        minVerticalPadding: 10,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: k.accent,
        linearTrackColor: k.track,
      ),
    );
  }
}
