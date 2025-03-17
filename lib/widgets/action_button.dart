import 'package:flutter/material.dart';
import 'package:goalock/theme/app_theme.dart';

/// 앱에서 사용되는 기본 액션 버튼
class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isDarkMode;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final double fontSize;
  final bool isFullWidth;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  const ActionButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.isDarkMode,
    this.backgroundColor,
    this.textColor,
    this.height = 56,
    this.fontSize = 18,
    this.isFullWidth = true,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: padding,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.primaryColor,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor ?? (isDarkMode ? Colors.black : Colors.white),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
