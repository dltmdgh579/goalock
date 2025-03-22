import 'package:flutter/material.dart';
import 'package:goalock/models/goal.dart';
import 'package:goalock/services/storage_service.dart';
import 'package:goalock/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class GoalSetupScreen extends StatefulWidget {
  final Goal? existingGoal; // 수정 시 기존 목표 전달

  const GoalSetupScreen({Key? key, this.existingGoal}) : super(key: key);

  @override
  _GoalSetupScreenState createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();
  String _selectedGoalType = '일반';
  DateTime? _deadline;
  int _importance = 2; // 1: 보통, 2: 중요, 3: 매우 중요
  bool _showOnLockScreen = true;
  late StorageService _storageService;

  final List<String> _goalTypes = [
    '일반',
    '자격증/학습',
    '운동/건강',
    '습관/루틴',
    '커리어/직장',
    '취미/여가',
  ];

  @override
  void initState() {
    super.initState();

    // 기존 목표 정보가 있으면 폼에 채우기
    if (widget.existingGoal != null) {
      _titleController.text = widget.existingGoal!.title;
      _motivationController.text =
          widget.existingGoal!.motivationalMessage ?? '';
      _selectedGoalType = widget.existingGoal!.goalType;
      _deadline = widget.existingGoal!.deadline;
      _importance = widget.existingGoal!.importance;
      _showOnLockScreen = widget.existingGoal!.showOnLockScreen;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storageService = Provider.of<StorageService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 헤더
          _buildHeader(),

          // 폼 영역
          Expanded(child: SingleChildScrollView(child: _buildForm())),
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
        child: Row(
          children: [
            // 뒤로가기 버튼
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
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
            const SizedBox(width: 20),
            // 헤더 제목
            const Text(
              "새 목표 설정",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 목표 제목 필드
          _buildFormLabel("목표 제목"),
          _buildTextField(controller: _titleController, hintText: "목표를 입력하세요"),
          const SizedBox(height: 20),

          // 목표 유형 선택
          _buildFormLabel("목표 유형"),
          _buildDropdownField(
            value: _selectedGoalType,
            items:
                _goalTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedGoalType = value;
                });
              }
            },
          ),
          const SizedBox(height: 20),

          // 목표 기한 선택
          _buildFormLabel("목표 기한 (선택)"),
          _buildDatePickerField(),
          const SizedBox(height: 20),

          // 중요도 선택
          _buildFormLabel("중요도"),
          _buildImportanceSelector(),
          const SizedBox(height: 20),

          // 잠금화면 표시 옵션
          _buildLockScreenToggle(),
          const SizedBox(height: 20),

          // 동기부여 메시지
          _buildFormLabel("동기부여 메시지 (선택)"),
          _buildTextField(
            controller: _motivationController,
            hintText: "나를 응원하는 메시지를 입력하세요",
            maxLines: 2,
          ),
          const SizedBox(height: 30),

          // 로드맵 설정 버튼
          _buildRoadmapButton(),
          const SizedBox(height: 20),

          // 저장 버튼
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEE2E6), width: 1),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEE2E6), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    final formatter = DateFormat('yyyy년 M월 d일');
    final displayText =
        _deadline != null ? formatter.format(_deadline!) : '날짜 선택';

    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDEE2E6), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayText,
              style: TextStyle(
                color: _deadline != null ? Colors.black : Colors.grey[500],
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF7165D6),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7165D6),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Widget _buildImportanceSelector() {
    return Row(
      children: [
        _buildImportanceButton(1, "보통"),
        const SizedBox(width: 10),
        _buildImportanceButton(2, "중요"),
        const SizedBox(width: 10),
        _buildImportanceButton(3, "매우 중요"),
      ],
    );
  }

  Widget _buildImportanceButton(int value, String label) {
    final isSelected = _importance == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _importance = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F3FA),
            borderRadius: BorderRadius.circular(20),
            border:
                isSelected
                    ? null
                    : Border.all(color: const Color(0xFFDEE2E6), width: 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockScreenToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "잠금화면에 표시",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          _buildToggleSwitch(
            value: _showOnLockScreen,
            onChanged: (value) {
              setState(() {
                _showOnLockScreen = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? AppTheme.primaryColor : Colors.grey[300],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 22 : 0,
              top: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapButton() {
    return GestureDetector(
      onTap: () {
        // TODO: 로드맵 설정 화면으로 이동 구현
        _showSnackBar("로드맵 설정 화면으로 이동");
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3FA),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppTheme.primaryColor, width: 1.5),
        ),
        child: Center(
          child: Text(
            "로드맵 설정하기",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveGoal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: AppTheme.headerGradient,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Center(
          child: Text(
            "저장하기",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _saveGoal() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnackBar("목표 제목을 입력해주세요");
      return;
    }

    try {
      if (widget.existingGoal != null) {
        // 기존 목표 수정
        final updatedGoal = widget.existingGoal!.copyWith(
          title: title,
          goalType: _selectedGoalType,
          deadline: _deadline,
          importance: _importance,
          showOnLockScreen: _showOnLockScreen,
          motivationalMessage: _motivationController.text.trim(),
        );

        await _storageService.updateGoal(updatedGoal);
        _showSnackBar("목표가 수정되었습니다");
      } else {
        // 새 목표 생성
        final newGoal = Goal(
          id: const Uuid().v4(),
          title: title,
          createdAt: DateTime.now(),
          deadline: _deadline,
          displayPeriod: 'Always', // 기본값
          goalType: _selectedGoalType,
          importance: _importance,
          showOnLockScreen: _showOnLockScreen,
          motivationalMessage: _motivationController.text.trim(),
        );

        await _storageService.createGoal(
          newGoal: newGoal,
          title: title, // 백업 옵션을 위해 title 전달
          displayPeriod: 'Always', // 백업 옵션을 위해 displayPeriod 전달
        );
        _showSnackBar("새 목표가 추가되었습니다");
      }

      // 화면 닫기
      Navigator.pop(context, true); // 결과 전달 (목표 저장됨)
    } catch (e) {
      _showSnackBar("오류가 발생했습니다: $e");
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
  void dispose() {
    _titleController.dispose();
    _motivationController.dispose();
    super.dispose();
  }
}
