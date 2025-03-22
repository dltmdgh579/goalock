import 'package:flutter/material.dart';
import 'package:goalock/models/goal.dart';
import 'package:goalock/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CompletedGoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const CompletedGoalDetailScreen({Key? key, required this.goal})
    : super(key: key);

  @override
  _CompletedGoalDetailScreenState createState() =>
      _CompletedGoalDetailScreenState();
}

class _CompletedGoalDetailScreenState extends State<CompletedGoalDetailScreen> {
  late Goal _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 헤더
          _buildHeader(),

          // 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 목표 정보 카드
                  _buildGoalInfoCard(),

                  const SizedBox(height: 25),

                  // 완료 정보 카드
                  _buildCompletionCard(),

                  const SizedBox(height: 25),

                  // 로드맵 (있는 경우)
                  if (_goal.hasRoadmap) ...[
                    _buildSectionTitle('로드맵'),
                    _buildRoadmap(),
                    const SizedBox(height: 25),
                  ],

                  // 메모 (있는 경우)
                  if (_goal.description != null &&
                      _goal.description!.isNotEmpty) ...[
                    _buildSectionTitle('메모'),
                    _buildDescriptionCard(),
                    const SizedBox(height: 25),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // 중요도에 따라 다른 그라데이션 색상 적용
    List<Color> gradientColors;
    switch (_goal.importance) {
      case 3:
        gradientColors = AppTheme.card3Gradient;
        break;
      case 2:
        gradientColors = AppTheme.card1Gradient;
        break;
      default:
        gradientColors = AppTheme.card2Gradient;
    }

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 뒤로가기 버튼
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 15),

              // 목표 제목
              Text(
                _goal.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // 목표 유형 및 완료 뱃지
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _goal.goalType,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '완료',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기본 정보
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 10),
              Text(
                '생성일: ${DateFormat('yyyy년 MM월 dd일').format(_goal.createdAt)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 기한 (있는 경우)
          if (_goal.deadline != null) ...[
            Row(
              children: [
                const Icon(Icons.date_range, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Text(
                  '목표 기한: ${DateFormat('yyyy년 MM월 dd일').format(_goal.deadline!)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],

          // 중요도
          _buildInfoRow(
            icon: Icons.star,
            title: '중요도',
            content: _getImportanceText(_goal.importance),
          ),

          // 동기부여 메시지 (있는 경우)
          if (_goal.motivationalMessage != null &&
              _goal.motivationalMessage!.isNotEmpty) ...[
            const Divider(height: 30),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _goal.motivationalMessage!,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완료 아이콘 및 제목
          Row(
            children: [
              Icon(Icons.emoji_events, size: 22, color: Colors.green[700]),
              const SizedBox(width: 10),
              Text(
                '목표 달성 완료!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 완료일
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
              const SizedBox(width: 10),
              Text(
                '완료일: ${DateFormat('yyyy년 MM월 dd일').format(_goal.completedAt ?? DateTime.now())}',
                style: TextStyle(fontSize: 14, color: Colors.green[600]),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 달성 기간
          Row(
            children: [
              Icon(Icons.timer, size: 18, color: Colors.green[600]),
              const SizedBox(width: 10),
              Text(
                '달성 기간: ${_calculateDuration()}',
                style: TextStyle(fontSize: 14, color: Colors.green[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateDuration() {
    final duration = (_goal.completedAt ?? DateTime.now()).difference(
      _goal.createdAt,
    );
    final days = duration.inDays;

    if (days == 0) {
      return '당일 달성';
    } else if (days < 30) {
      return '$days일';
    } else if (days < 365) {
      final months = (days / 30).floor();
      final remainingDays = days % 30;
      return '$months개월 ${remainingDays > 0 ? '$remainingDays일' : ''}';
    } else {
      final years = (days / 365).floor();
      final remainingMonths = ((days % 365) / 30).floor();
      return '$years년 ${remainingMonths > 0 ? '$remainingMonths개월' : ''}';
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
    Color? contentColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const Spacer(),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: contentColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  String _getImportanceText(int importance) {
    switch (importance) {
      case 3:
        return '높음';
      case 2:
        return '중간';
      default:
        return '낮음';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRoadmap() {
    final steps = _goal.roadmapSteps!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 진행률 표시
          _buildProgressBar(_goal.roadmapProgress),
          const SizedBox(height: 20),

          // 로드맵 단계들
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            return _buildRoadmapStep(step);
          }),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '달성률',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: progress == 1.0 ? Colors.green : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      progress == 1.0
                          ? [Colors.green, Colors.green.shade300]
                          : AppTheme.headerGradient,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmapStep(RoadmapStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 체크박스 (읽기 전용)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.isCompleted ? Colors.green : Colors.grey[200],
              border: Border.all(
                color: step.isCompleted ? Colors.green : Colors.grey,
                width: 1.5,
              ),
            ),
            child:
                step.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
          ),
          const SizedBox(width: 15),

          // 단계 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: step.isCompleted ? Colors.grey : Colors.black,
                    decoration:
                        step.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (step.description != null && step.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      step.description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                if (step.completedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '완료일: ${DateFormat('yyyy년 MM월 dd일').format(step.completedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        _goal.description!,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }
}
