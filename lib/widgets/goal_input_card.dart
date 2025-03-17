import 'package:flutter/material.dart';

/// 목표 입력을 위한 카드 위젯
class GoalInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final String hintText;
  final Function(String)? onSubmitted;

  const GoalInputCard({
    Key? key,
    required this.controller,
    required this.isDarkMode,
    this.hintText = "오늘의 목표를 입력하세요",
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontStyle: FontStyle.italic,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.done,
        maxLines: null,
        keyboardType: TextInputType.multiline,
      ),
    );
  }
}
