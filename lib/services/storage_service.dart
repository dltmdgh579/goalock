import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goalock/models/goal.dart';
import 'package:uuid/uuid.dart';

/// 앱 데이터 저장 및 관리를 위한 서비스
class StorageService {
  static const String _currentGoalKey = 'currentGoal';
  static const String _goalsKey = 'goals';
  static const String _archivedGoalsKey = 'archivedGoals';

  /// 현재 목표 저장
  Future<void> saveCurrentGoal(String goalText) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentGoalKey, goalText);
  }

  /// 현재 목표 불러오기
  Future<String?> getCurrentGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentGoalKey);
  }

  /// 새 목표 생성 및 저장
  Future<Goal> createGoal({
    required String title,
    String? description,
    required String displayPeriod,
    Goal? newGoal,
  }) async {
    // 새 목표 객체가 직접 전달된 경우
    if (newGoal != null) {
      final goals = await getAllGoals();
      goals.insert(0, newGoal);
      await _saveGoals(goals);
      return newGoal;
    }

    // 기존 방식으로 목표 생성
    final goal = Goal(
      id: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      displayPeriod: displayPeriod,
    );

    final goals = await getAllGoals();
    goals.insert(0, goal);
    await _saveGoals(goals);

    return goal;
  }

  /// 모든 목표 불러오기
  Future<List<Goal>> getAllGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList(_goalsKey) ?? [];

    return goalsJson
        .map((json) => Goal.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  /// 목표 목록 저장
  Future<void> _saveGoals(List<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = goals.map((goal) => jsonEncode(goal.toJson())).toList();

    await prefs.setStringList(_goalsKey, goalsJson);
  }

  /// 목표 업데이트
  Future<void> updateGoal(Goal goal) async {
    final goals = await getAllGoals();
    final index = goals.indexWhere((g) => g.id == goal.id);

    if (index != -1) {
      goals[index] = goal;
      await _saveGoals(goals);
    }
  }

  /// 목표 삭제
  Future<void> deleteGoal(String goalId) async {
    final goals = await getAllGoals();
    goals.removeWhere((goal) => goal.id == goalId);
    await _saveGoals(goals);
  }

  /// 완료된 목표 아카이브에 추가
  Future<void> archiveGoal(Goal goal) async {
    // 목표를 완료 상태로 변경
    final completedGoal = goal.markAsCompleted();
    await updateGoal(completedGoal);

    // 아카이브에 추가
    final prefs = await SharedPreferences.getInstance();
    List<String> archivedGoals = prefs.getStringList(_archivedGoalsKey) ?? [];
    archivedGoals.add(jsonEncode(completedGoal.toJson()));
    await prefs.setStringList(_archivedGoalsKey, archivedGoals);
  }

  /// 아카이브된 목표 불러오기
  Future<List<Goal>> getArchivedGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final archivedGoalsJson = prefs.getStringList(_archivedGoalsKey) ?? [];

    return archivedGoalsJson
        .map((json) => Goal.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }
}
