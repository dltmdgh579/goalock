import 'package:flutter/material.dart';
import 'package:goalock/models/goal.dart';
import 'package:goalock/screens/archive_screen.dart';
import 'package:goalock/screens/lock_screen_settings.dart';
import 'package:goalock/services/storage_service.dart';
import 'package:goalock/theme/app_theme.dart';
import 'package:goalock/widgets/goal_card.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:goalock/services/custom_lock_screen_service.dart';
import 'package:goalock/screens/goal_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StorageService _storageService;
  late CustomLockScreenService _lockScreenService;
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context, listen: false);
    _lockScreenService = CustomLockScreenService();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });

    final goals = await _storageService.getAllGoals();

    // 완료되지 않은 목표만 필터링
    final activeGoals = goals.where((goal) => !goal.isCompleted).toList();

    setState(() {
      // 목표가 없으면 샘플 데이터 사용
      if (activeGoals.isEmpty) {
        _goals = _getSampleGoals();
      } else {
        _goals = activeGoals;
      }
      _isLoading = false;
    });
  }

  // 샘플 목표 데이터
  List<Goal> _getSampleGoals() {
    return [
      Goal(
        id: '1',
        title: '정보처리기사 자격증 따기',
        createdAt: DateTime.now(),
        deadline: DateTime.now().add(const Duration(days: 102)),
        displayPeriod: 'Always',
        goalType: '자격증/학습',
        importance: 3,
        showOnLockScreen: true,
        motivationalMessage: '오늘 한 걸음이 내일의 큰 성과를 만듭니다.',
        roadmapSteps: [
          RoadmapStep(order: 1, title: '기본 이론 공부', isCompleted: true),
          RoadmapStep(order: 2, title: '기출문제 풀이', isCompleted: true),
          RoadmapStep(order: 3, title: '실전 모의고사', isCompleted: false),
          RoadmapStep(order: 4, title: '최종 시험 응시', isCompleted: false),
        ],
        currentStep: 3,
      ),
      Goal(
        id: '2',
        title: '몸무게 65kg 만들기',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        displayPeriod: 'Always',
        goalType: '운동/건강',
        importance: 2,
        showOnLockScreen: true,
      ),
      Goal(
        id: '3',
        title: '러닝 10km 달성하기',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        deadline: DateTime.now().add(const Duration(days: 25)),
        displayPeriod: 'Once a Day',
        goalType: '운동/건강',
        importance: 2,
        motivationalMessage: '작은 노력이 모여 큰 변화를 만듭니다.',
      ),
    ];
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LockScreenSettings()),
    );
  }

  void _navigateToArchive() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ArchiveScreen()),
    );
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
      body: Column(
        children: [
          // 헤더 영역
          _buildHeader(),

          // 목표 리스트 영역
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _goals.isEmpty
                    ? _buildEmptyState()
                    : _buildGoalsList(),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.headerGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _navigateToGoalSetup(),
            child: const Center(
              child: Text(
                "+",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToGoalSetup() async {
    // 목표 설정 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalSetupScreen()),
    );

    // 새 목표가 추가되었으면 목록 리로드
    if (result == true) {
      _loadGoals();
    }
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
                  "내 목표",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    // 설정 버튼
                    _buildHeaderIconButton(
                      icon: Icons.settings,
                      onTap: _navigateToSettings,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "꿈을 현실로 만드는 여정",
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

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildGoalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return GoalCard(
          goal: goal,
          cardIndex: index,
          onTap: () {
            // 목표 상세 화면으로 이동
            _showSnackBar("목표 상세 화면으로 이동");
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "목표가 없습니다",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "오른쪽 하단의 + 버튼을 눌러 새 목표를 추가하세요",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
