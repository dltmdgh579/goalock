import 'package:flutter/material.dart';
import 'package:goalock/services/lock_screen_service.dart';

/// 앱의 이전 코드와의 호환성을 위한 래퍼 클래스
class CustomLockScreenService {
  /// 서비스 활성화 상태
  bool _isEnabled = false;

  /// 서비스 활성화 여부 확인
  bool get isEnabled => _isEnabled;

  /// 권한 요청
  Future<bool> requestPermissions() async {
    try {
      return await LockScreenService.requestPermissions();
    } catch (e) {
      debugPrint('권한 요청 오류: $e');
      return false;
    }
  }

  /// 잠금화면 서비스 활성화
  Future<bool> enableLockScreenService({
    required String goalText,
    Color backgroundColor = const Color(0xFF4CAF50),
    Color textColor = Colors.white,
  }) async {
    try {
      // 목표 텍스트 설정
      await LockScreenService.setGoalText(goalText);

      // 색상 설정
      final bgHex = '#${backgroundColor.value.toRadixString(16).substring(2)}';
      final textHex = '#${textColor.value.toRadixString(16).substring(2)}';

      await LockScreenService.setBackgroundColor(bgHex);
      await LockScreenService.setTextColor(textHex);

      // 서비스 활성화
      final result = await LockScreenService.startService();
      _isEnabled = result;
      return result;
    } catch (e) {
      debugPrint('잠금화면 서비스 활성화 오류: $e');
      return false;
    }
  }

  /// 잠금화면 서비스 비활성화
  Future<bool> disableLockScreenService() async {
    try {
      final result = await LockScreenService.stopService();
      _isEnabled = !result;
      return result;
    } catch (e) {
      debugPrint('잠금화면 서비스 비활성화 오류: $e');
      return false;
    }
  }
}
