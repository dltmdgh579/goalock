import 'package:flutter/material.dart';
import 'package:goalock/models/goal.dart';
import 'package:goalock/screens/completed_goal_detail_screen.dart';
import 'package:goalock/services/storage_service.dart';
import 'package:goalock/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  _ArchiveScreenState createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  late StorageService _storageService;
  List<Goal> _archivedGoals = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context, listen: false);
    _loadArchivedGoals();
  }

  Future<void> _loadArchivedGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final goals = await _storageService.getArchivedGoals();
      goals.sort(
        (a, b) => (b.completedAt ?? DateTime.now()).compareTo(
          a.completedAt ?? DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _archivedGoals = goals;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('아카이브 목표 로딩 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 헤더 영역
          _buildHeader(),

          // 본문 영역
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _archivedGoals.isEmpty
                    ? _buildEmptyState()
                    : _buildArchivedGoalsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: AppTheme.headerGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "완료된 목표",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "달성한 성취의 기록",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedGoalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _archivedGoals.length,
      itemBuilder: (context, index) {
        final goal = _archivedGoals[index];
        return _buildArchivedGoalCard(goal, index);
      },
    );
  }

  Widget _buildArchivedGoalCard(Goal goal, int index) {
    // 카드 색상 계산
    List<Color> cardColors;
    switch (index % 3) {
      case 0:
        cardColors = AppTheme.card1Gradient;
        break;
      case 1:
        cardColors = AppTheme.card2Gradient;
        break;
      default:
        cardColors = AppTheme.card3Gradient;
    }

    return GestureDetector(
      onTap: () => _navigateToGoalDetail(goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cardColors,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 - 완료일 및 중요도
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      goal.goalType,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '완료: ${DateFormat('yyyy년 MM월 dd일').format(goal.completedAt ?? DateTime.now())}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 목표 제목
              Text(
                goal.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // 로드맵 진행 상태 (있는 경우)
              if (goal.hasRoadmap) ...[
                const SizedBox(height: 15),
                _buildProgressIndicator(goal),
              ],

              // 동기부여 메시지 (있는 경우)
              if (goal.motivationalMessage != null &&
                  goal.motivationalMessage!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '"${goal.motivationalMessage}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(Goal goal) {
    final progress = goal.roadmapProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '달성률',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "완료된 목표가 없습니다",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "목표를 달성하면 이곳에서 확인할 수 있습니다",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  // 완료된 목표 상세 화면으로 이동
  void _navigateToGoalDetail(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompletedGoalDetailScreen(goal: goal),
      ),
    );
  }
}
