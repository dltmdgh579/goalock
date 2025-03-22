import 'package:flutter/material.dart';
import 'package:goalock/models/goal.dart';
import 'package:goalock/screens/goal_setup_screen.dart';
import 'package:goalock/services/storage_service.dart';
import 'package:goalock/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({Key? key, required this.goal}) : super(key: key);

  @override
  _GoalDetailScreenState createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late Goal _goal;
  late StorageService _storageService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context, listen: false);
  }

  // 로드맵 단계 완료 상태 토글
  Future<void> _toggleStepCompletion(int index) async {
    setState(() => _isLoading = true);

    try {
      // 로드맵 단계 복사
      final updatedSteps = List<RoadmapStep>.from(_goal.roadmapSteps ?? []);

      // 단계 완료 상태 토글
      final currentStep = updatedSteps[index];
      if (currentStep.isCompleted) {
        updatedSteps[index] = currentStep.copyWith(
          isCompleted: false,
          completedAt: null,
        );
      } else {
        updatedSteps[index] = currentStep.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
      }

      // 현재 단계 업데이트
      int completedCount =
          updatedSteps.where((step) => step.isCompleted).length;
      int newCurrentStep = completedCount + 1;
      if (newCurrentStep > updatedSteps.length) {
        newCurrentStep = updatedSteps.length;
      }

      // 목표 업데이트
      final updatedGoal = _goal.copyWith(
        roadmapSteps: updatedSteps,
        currentStep: newCurrentStep,
      );

      await _storageService.updateGoal(updatedGoal);

      setState(() {
        _goal = updatedGoal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('로드맵 단계 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  // 목표 편집
  Future<void> _editGoal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalSetupScreen(existingGoal: _goal),
      ),
    );

    if (result == true) {
      // 목표가 업데이트되었으면 다시 로드
      final updatedGoal = (await _storageService.getAllGoals()).firstWhere(
        (g) => g.id == _goal.id,
      );

      setState(() {
        _goal = updatedGoal;
      });
    }
  }

  // 목표 삭제
  Future<void> _deleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('목표 삭제'),
            content: const Text('정말로 이 목표를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _storageService.deleteGoal(_goal.id);
        if (mounted) {
          Navigator.pop(context, true); // 삭제 결과 전달
        }
      } catch (e) {
        _showSnackBar('목표 삭제 중 오류가 발생했습니다: $e');
      }
    }
  }

  // 목표 완료
  Future<void> _completeGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('목표 완료'),
            content: const Text('이 목표를 완료로 표시하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('완료', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _storageService.archiveGoal(_goal);
        if (mounted) {
          Navigator.pop(context, true); // 완료 결과 전달
        }
      } catch (e) {
        _showSnackBar('목표 완료 처리 중 오류가 발생했습니다: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
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

                          // 버튼 영역
                          _buildActionButtons(),
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

              // 목표 유형과 생성일
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
                  Text(
                    '생성일: ${DateFormat('yyyy년 MM월 dd일').format(_goal.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
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
          // 기한 (있는 경우)
          if (_goal.deadline != null) ...[
            _buildInfoRow(
              icon: Icons.calendar_today,
              title: '목표 기한',
              content: DateFormat('yyyy년 MM월 dd일').format(_goal.deadline!),
            ),
            const SizedBox(height: 15),
            _buildInfoRow(
              icon: Icons.timer,
              title: '남은 일수',
              content: 'D-${_goal.daysRemaining}',
              contentColor: _goal.daysRemaining! < 7 ? Colors.red : null,
            ),
            const Divider(height: 30),
          ],

          // 중요도
          _buildInfoRow(
            icon: Icons.star,
            title: '중요도',
            content: _getImportanceText(_goal.importance),
          ),

          const SizedBox(height: 15),

          // 잠금화면 표시 여부
          _buildInfoRow(
            icon: Icons.phone_android,
            title: '잠금화면 표시',
            content: _goal.showOnLockScreen ? '표시' : '숨김',
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
            return _buildRoadmapStep(step, index);
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
              '진행률',
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

  Widget _buildRoadmapStep(RoadmapStep step, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 체크박스
          GestureDetector(
            onTap: () => _toggleStepCompletion(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    step.isCompleted ? AppTheme.primaryColor : Colors.grey[200],
                border: Border.all(
                  color: step.isCompleted ? AppTheme.primaryColor : Colors.grey,
                  width: 1.5,
                ),
              ),
              child:
                  step.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
            ),
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 삭제 버튼
        _buildActionButton(
          icon: Icons.delete,
          label: '삭제하기',
          color: Colors.red,
          onTap: _deleteGoal,
        ),

        // 편집 버튼
        _buildActionButton(
          icon: Icons.edit,
          label: '편집하기',
          color: Colors.orange,
          onTap: _editGoal,
        ),

        // 완료 버튼
        _buildActionButton(
          icon: Icons.check_circle,
          label: '완료하기',
          color: Colors.green,
          onTap: _completeGoal,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
