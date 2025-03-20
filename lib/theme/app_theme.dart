import 'package:flutter/material.dart';

/// 앱 전체에서 사용되는 테마 설정을 관리하는 클래스
class AppTheme {
  // 앱에서 사용되는 주요 색상
  static const Color primaryColor = Color(0xFF5e72e4); // 파란색 기본
  static const Color secondaryColor = Color(0xFF825ee4); // 보라색 보조
  static const Color accentColor = Color(0xFF4facfe); // 하늘색 액센트

  // 추가 그라데이션 컬러들
  static const Color cardGradient1Start = Color(0xFF4facfe); // 카드 그라데이션 1 시작
  static const Color cardGradient1End = Color(0xFF00f2fe); // 카드 그라데이션 1 끝

  static const Color cardGradient2Start = Color(0xFFff9a9e); // 카드 그라데이션 2 시작
  static const Color cardGradient2End = Color(0xFFfad0c4); // 카드 그라데이션 2 끝

  static const Color cardGradient3Start = Color(0xFF667eea); // 카드 그라데이션 3 시작
  static const Color cardGradient3End = Color(0xFF764ba2); // 카드 그라데이션 3 끝

  // 라이트 테마 설정
  static final ThemeData lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFf8f9fe),
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Color(0xFF525f7f))),
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
  static const List<Color> lightGradient = [Color(0xFFf8f9fe), Colors.white];

  // 그라데이션 배경 (다크 모드)
  static const List<Color> darkGradient = [Color(0xFF212121), Colors.black];

  // 헤더 그라데이션
  static const List<Color> headerGradient = [primaryColor, secondaryColor];

  // 카드 그라데이션들
  static const List<Color> card1Gradient = [
    cardGradient1Start,
    cardGradient1End,
  ];
  static const List<Color> card2Gradient = [
    cardGradient2Start,
    cardGradient2End,
  ];
  static const List<Color> card3Gradient = [
    cardGradient3Start,
    cardGradient3End,
  ];
}
