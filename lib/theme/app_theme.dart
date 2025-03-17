import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 테마 설정을 관리하는 클래스
class AppTheme {
  // 앱에서 사용되는 주요 색상
  static const Color primaryColor = Color(0xFF4CAF50); // 네온 민트
  static const Color secondaryColor = Color(0xFF2E7D32);
  static const Color accentColor = Color(0xFF81C784);

  // 라이트 테마 설정
  static final ThemeData lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black87)),
    cardColor: Colors.white,
    buttonTheme: const ButtonThemeData(buttonColor: primaryColor),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.grey;
      }),
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(
        fontStyle: FontStyle.italic,
        color: Colors.grey[600],
      ),
    ),
  );

  // 다크 테마 설정
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
    cardColor: Colors.grey[800],
    buttonTheme: const ButtonThemeData(buttonColor: primaryColor),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.grey;
      }),
      checkColor: MaterialStateProperty.all(Colors.black),
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(
        fontStyle: FontStyle.italic,
        color: Colors.grey[400],
      ),
    ),
  );

  // 그라데이션 배경 (라이트 모드)
  static const List<Color> lightGradient = [Color(0xFFE0E0E0), Colors.white];

  // 그라데이션 배경 (다크 모드)
  static const List<Color> darkGradient = [Color(0xFF212121), Colors.black];
}
