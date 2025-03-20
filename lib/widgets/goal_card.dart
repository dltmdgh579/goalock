import 'package:flutter/material.dart';
import 'package:goalock/models/goal.dart';
import 'package:goalock/theme/app_theme.dart';
import 'package:intl/intl.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final int cardIndex; // 카드 인덱스에 따라 다른 그라데이션 적용

  const GoalCard({Key? key, required this.goal, this.onTap, this.cardIndex = 0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 목표 제목
            Text(
              goal.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // 목표 기한 또는 진행 상태
            _buildGoalStatus(),

            const SizedBox(height: 10),

            // 남은 일수 또는 추가 정보
            if (goal.daysRemaining != null) _buildDaysRemaining(),

            const SizedBox(height: 5),

            // 동기부여 메시지 (있는 경우)
            if (goal.motivationalMessage != null &&
                goal.motivationalMessage!.isNotEmpty)
              Text(
                '"${goal.motivationalMessage}"',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalStatus() {
    if (goal.deadline != null) {
      final formatter = DateFormat('yyyy년 M월 d일');
      return Text(
        '목표 기한: ${formatter.format(goal.deadline!)}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
    } else if (goal.hasRoadmap) {
      final currentStep = goal.currentStep ?? 0;
      final totalSteps = goal.roadmapSteps?.length ?? 0;
      return Text(
        '로드맵 진행 중 ($currentStep/$totalSteps)',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
    } else {
      return Text(
        '현재 진행 중',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
    }
  }

  Widget _buildDaysRemaining() {
    return Text(
      'D-${goal.daysRemaining}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  List<Color> _getGradientColors() {
    // 카드 인덱스에 따라 다른 그라데이션 적용
    switch (cardIndex % 3) {
      case 0:
        return AppTheme.card1Gradient;
      case 1:
        return AppTheme.card2Gradient;
      case 2:
        return AppTheme.card3Gradient;
      default:
        return AppTheme.card1Gradient;
    }
  }
}
