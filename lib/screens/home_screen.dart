import 'package:flutter/material.dart';
import 'package:goalock/models/goal.dart';
import 'package:goalock/screens/archive_screen.dart';
import 'package:goalock/screens/lock_screen_settings.dart';
import 'package:goalock/services/storage_service.dart';
import 'package:goalock/theme/app_theme.dart';
import 'package:goalock/widgets/action_button.dart';
import 'package:goalock/widgets/goal_input_card.dart';
import 'package:goalock/widgets/period_selector.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:goalock/services/custom_lock_screen_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _goalController = TextEditingController();
  String _selectedPeriod = "Always";
  bool _isChecked = false;
  bool _isDarkMode = false;
  bool _isLockScreenEnabled = false;

  late StorageService _storageService;
  late CustomLockScreenService _lockScreenService;

  @override
  void initState() {
    super.initState();
    // Provider에서 서비스를 가져오는 것은 didChangeDependencies에서 수행
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context, listen: false);
    _lockScreenService = CustomLockScreenService();
    _loadCurrentGoal();
  }

  Future<void> _loadCurrentGoal() async {
    final currentGoal = await _storageService.getCurrentGoal();
    if (currentGoal != null && currentGoal.isNotEmpty && mounted) {
      setState(() {
        _goalController.text = currentGoal;
      });
    }
  }

  Future<void> _setLockScreen() async {
    final goalText = _goalController.text;
    if (goalText.isEmpty) {
      _showSnackBar("목표를 입력해주세요");
      return;
    }

    try {
      _showSnackBar("잠금 화면 설정 중...");

      final hasPermission = await _lockScreenService.requestPermissions();
      if (!hasPermission) {
        _showSnackBar("권한이 없어 잠금화면을 설정할 수 없습니다.");
        return;
      }

      final backgroundColor = AppTheme.primaryColor;
      final textColor = Colors.white;

      final success = await _lockScreenService.enableLockScreenService(
        goalText: goalText,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );

      if (success) {
        setState(() {
          _isLockScreenEnabled = true;
        });
        _showSnackBar("잠금 화면 설정 완료!");

        // 목표 저장
        await _saveGoal();
      } else {
        _showSnackBar("잠금 화면 설정에 실패했습니다. 다시 시도해주세요.");
      }
    } catch (e) {
      debugPrint("잠금화면 설정 오류: $e");
      _showSnackBar("오류 발생: 앱을 재시작하고 다시 시도해주세요");
    }
  }

  Future<void> _disableLockScreen() async {
    try {
      _showSnackBar("잠금 화면 비활성화 중...");

      final success = await _lockScreenService.disableLockScreenService();

      if (success) {
        setState(() {
          _isLockScreenEnabled = false;
        });
        _showSnackBar("잠금 화면이 비활성화되었습니다.");
      } else {
        _showSnackBar("잠금 화면 비활성화에 실패했습니다.");
      }
    } catch (e) {
      debugPrint("잠금화면 비활성화 오류: $e");
      _showSnackBar("오류 발생: 앱을 재시작하고 다시 시도해주세요");
    }
  }

  Future<void> _saveGoal() async {
    final goalText = _goalController.text;
    if (goalText.isEmpty) return;

    // 현재 목표 텍스트 저장
    await _storageService.saveCurrentGoal(goalText);

    // 목표 객체 생성 및 저장
    await _storageService.createGoal(
      title: goalText,
      displayPeriod: _selectedPeriod,
    );
  }

  Future<void> _completeGoal() async {
    final goalText = _goalController.text;
    if (goalText.isEmpty) return;

    // 임시로 ID 생성 (실제로는 저장된 목표 ID를 사용해야 함)
    final goal = Goal(
      id: const Uuid().v4(),
      title: goalText,
      createdAt: DateTime.now(),
      displayPeriod: _selectedPeriod,
    );

    // 목표 아카이브에 추가
    await _storageService.archiveGoal(goal);

    _showSnackBar("목표가 완료 처리되었습니다");
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

  void _resetGoal() {
    setState(() {
      _goalController.clear();
      _isChecked = false;
    });
  }

  void _navigateToArchive() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ArchiveScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 앱 헤더
                _buildAppHeader(isDark),
                const SizedBox(height: 32),

                // 목표 입력 필드
                _buildGoalInputSection(isDark),
                const SizedBox(height: 32),

                const Spacer(),

                // 액션 버튼 섹션
                _buildActionButtons(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flag_rounded,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "GoalLock",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildIconButton(
              icon: Icons.archive_outlined,
              onPressed: _navigateToArchive,
              isDark: isDark,
            ),
            _buildIconButton(
              icon: Icons.lock_outline,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LockScreenSettings(),
                  ),
                );
              },
              isDark: isDark,
            ),
            _buildIconButton(
              icon:
                  isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: AppTheme.primaryColor,
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildGoalInputSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "오늘의 목표",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // 목표 입력 필드
        GoalInputCard(controller: _goalController, isDarkMode: isDark),
        const SizedBox(height: 24),

        // 표시 주기 선택
        PeriodSelector(
          selectedPeriod: _selectedPeriod,
          onPeriodSelected:
              (period) => setState(() => _selectedPeriod = period),
          isDarkMode: isDark,
        ),
        const SizedBox(height: 24),

        // 목표 달성 체크박스
        InkWell(
          onTap: () {
            setState(() => _isChecked = !_isChecked);
            if (_isChecked) {
              _completeGoal();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  _isChecked
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color:
                        _isChecked ? AppTheme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          _isChecked
                              ? AppTheme.primaryColor
                              : isDark
                              ? Colors.white70
                              : Colors.black54,
                      width: 2,
                    ),
                  ),
                  child:
                      _isChecked
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Text(
                  "목표 달성",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        _isChecked
                            ? AppTheme.primaryColor
                            : isDark
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        // 잠금화면 버튼
        Container(
          width: double.infinity,
          height: 56,
          margin: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton(
            onPressed:
                _isLockScreenEnabled ? _disableLockScreen : _setLockScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isLockScreenEnabled
                      ? Colors.redAccent
                      : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isLockScreenEnabled
                      ? Icons.lock_open_outlined
                      : Icons.lock_outline,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _isLockScreenEnabled ? "잠금화면 비활성화" : "잠금화면 활성화",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 새 목표 추가 버튼
        Container(
          width: double.infinity,
          height: 56,
          margin: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton(
            onPressed: _resetGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
              foregroundColor: isDark ? Colors.white : Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  "새 목표 추가하기",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }
}
