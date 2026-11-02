import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_colors.dart';

abstract final class AppText {
  static const ui = 'SpaceGrotesk';
  static const mono = 'JetBrainsMono';

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.text,
    double letterSpacing = -0.5,
  }) {
    return TextStyle(
      fontFamily: ui,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: 1.1,
    );
  }

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double letterSpacing = 0,
    double height = 1.35,
  }) {
    return TextStyle(
      fontFamily: ui,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle data(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.text,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: mono,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.1,
    );
  }
}

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.lime,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.coral,
      onSecondary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.coral,
      onError: AppColors.onAccent,
    );

    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppText.ui,
      splashFactory: NoSplash.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      highlightColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.lime,
        selectionColor: Color(0x55C6F432),
        selectionHandleColor: AppColors.lime,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: AppText.body(14, color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        showDragHandle: true,
        dragHandleColor: AppColors.slate,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

final NumberFormat _money = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 2,
);
final NumberFormat _whole = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

String formatMoney(int cents, {bool showCents = true}) {
  if (cents % 100 == 0 && !showCents) return _whole.format(cents / 100);
  return _money.format(cents / 100);
}

String formatSignedMoney(int cents, {required bool isIncome}) {
  final value = formatMoney(cents, showCents: cents % 100 != 0);
  return '${isIncome ? '+' : '-'}$value';
}

String formatMonth(DateTime date) =>
    DateFormat('MMM yyyy', 'en_US').format(date).toUpperCase();

String formatRange(DateTime from, DateTime to) {
  final start = DateFormat('MMM d', 'en_US').format(from);
  final end = DateFormat('MMM d', 'en_US').format(to);
  return '$start – $end, ${to.year}';
}

String formatDayLabel(DateTime date) =>
    DateFormat('EEE, MMM d', 'en_US').format(date);

String weekdayName(int weekday) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[(weekday - 1).clamp(0, 6)];
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

DateTime monthStart(DateTime date) => DateTime(date.year, date.month);
DateTime monthEnd(DateTime date) => DateTime(date.year, date.month + 1, 0, 23, 59);
