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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 앱 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "GoalLock",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.archive_outlined),
                          color: AppTheme.primaryColor,
                          onPressed: _navigateToArchive,
                        ),
                        IconButton(
                          icon: const Icon(Icons.lock_outline),
                          color: AppTheme.primaryColor,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const LockScreenSettings(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.wb_sunny : Icons.nights_stay,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed:
                              () => setState(() => _isDarkMode = !_isDarkMode),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 목표 입력 필드
                GoalInputCard(controller: _goalController, isDarkMode: isDark),
                const SizedBox(height: 20),

                // 표시 주기 선택
                PeriodSelector(
                  selectedPeriod: _selectedPeriod,
                  onPeriodSelected:
                      (period) => setState(() => _selectedPeriod = period),
                  isDarkMode: isDark,
                ),
                const SizedBox(height: 20),

                // 목표 달성 체크박스
                Row(
                  children: [
                    Checkbox(
                      value: _isChecked,
                      onChanged: (bool? value) {
                        setState(() => _isChecked = value ?? false);
                        if (value ?? false) {
                          _completeGoal();
                        }
                      },
                      shape: const CircleBorder(),
                      activeColor: AppTheme.primaryColor,
                      checkColor: isDark ? Colors.black : Colors.white,
                    ),
                    const Text("목표 달성", style: TextStyle(fontSize: 16)),
                  ],
                ),

                const Spacer(),

                // 잠금화면 버튼
                ActionButton(
                  text: _isLockScreenEnabled ? "잠금화면 비활성화" : "잠금화면 활성화",
                  onPressed:
                      _isLockScreenEnabled
                          ? _disableLockScreen
                          : _setLockScreen,
                  isDarkMode: isDark,
                  backgroundColor:
                      _isLockScreenEnabled ? Colors.red : AppTheme.primaryColor,
                ),
                const SizedBox(height: 20),

                // 새 목표 추가 버튼
                Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    onPressed: _resetGoal,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(
                      Icons.add,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }
}
