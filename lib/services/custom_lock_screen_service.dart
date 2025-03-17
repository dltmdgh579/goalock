import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 커스텀 잠금화면 서비스
class CustomLockScreenService {
  static const platform = MethodChannel('com.goalock.app/lockscreen');

  /// 커스텀 잠금화면 서비스 활성화 상태
  bool _isEnabled = false;

  /// 서비스 활성화 여부 확인
  bool get isEnabled => _isEnabled;

  /// 필요한 권한 요청
  Future<bool> requestPermissions() async {
    try {
      // 안드로이드 네이티브 코드를 통한 권한 요청
      final bool result = await platform.invokeMethod('requestPermissions');
      return result;
    } on PlatformException catch (e) {
      debugPrint('권한 요청 오류: ${e.message}');
      return false;
    }
  }

  /// 커스텀 잠금화면 서비스 활성화
  Future<bool> enableLockScreenService({
    required String goalText,
    Color backgroundColor = const Color(0xFF4CAF50),
    Color textColor = Colors.white,
  }) async {
    try {
      // 권한 요청
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint('필요한 권한이 없습니다');
        return false;
      }

      // 안드로이드 네이티브 코드를 통해 서비스 활성화
      final bool result = await platform
          .invokeMethod('enableLockScreenService', {
            'goalText': goalText,
            'backgroundColor': backgroundColor.value,
            'textColor': textColor.value,
          });

      _isEnabled = result;
      return result;
    } on PlatformException catch (e) {
      debugPrint('잠금화면 서비스 활성화 오류: ${e.message}');
      return false;
    }
  }

  /// 커스텀 잠금화면 서비스 비활성화
  Future<bool> disableLockScreenService() async {
    try {
      // 안드로이드 네이티브 코드를 통해 서비스 비활성화
      final bool result = await platform.invokeMethod(
        'disableLockScreenService',
      );
      _isEnabled = !result;
      return result;
    } on PlatformException catch (e) {
      debugPrint('잠금화면 서비스 비활성화 오류: ${e.message}');
      return false;
    }
  }

  /// 잠금화면 목표 텍스트 업데이트
  Future<bool> updateGoalText(String goalText) async {
    if (!_isEnabled) {
      debugPrint('잠금화면 서비스가 활성화되지 않았습니다');
      return false;
    }

    try {
      // 안드로이드 네이티브 코드를 통해 목표 텍스트 업데이트
      final bool result = await platform.invokeMethod('updateGoalText', {
        'goalText': goalText,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('목표 텍스트 업데이트 오류: ${e.message}');
      return false;
    }
  }
}
