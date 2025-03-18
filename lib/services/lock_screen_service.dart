import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 안드로이드 네이티브 잠금화면 서비스를 제어하는 클래스
class LockScreenService {
  static const MethodChannel _channel = MethodChannel(
    'com.goalock.app/lockscreen',
  );
  static const String _prefsKeyServiceEnabled = 'lockScreenServiceEnabled';

  /// 잠금화면 서비스 시작
  static Future<bool> startService() async {
    try {
      final result = await _channel.invokeMethod('startLockScreenService');
      if (result == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefsKeyServiceEnabled, true);
      }
      return result;
    } on PlatformException catch (e) {
      print('잠금화면 서비스 시작 실패: ${e.message}');
      return false;
    }
  }

  /// 잠금화면 서비스 중지
  static Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod('stopLockScreenService');
      if (result == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefsKeyServiceEnabled, false);
      }
      return result;
    } on PlatformException catch (e) {
      print('잠금화면 서비스 중지 실패: ${e.message}');
      return false;
    }
  }

  /// 잠금화면 서비스 활성화 상태 확인
  static Future<bool> isServiceEnabled() async {
    try {
      final result = await _channel.invokeMethod('isLockScreenServiceEnabled');
      return result;
    } on PlatformException catch (e) {
      print('잠금화면 서비스 상태 확인 실패: ${e.message}');

      // 메서드 채널 연결 실패 시 SharedPreferences에서 확인
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefsKeyServiceEnabled) ?? false;
    }
  }

  /// 목표 텍스트 설정
  static Future<bool> setGoalText(String text) async {
    try {
      final result = await _channel.invokeMethod('setGoalText', {'text': text});
      return result;
    } on PlatformException catch (e) {
      print('목표 텍스트 설정 실패: ${e.message}');
      return false;
    }
  }

  /// 잠금화면 배경색 설정
  static Future<bool> setBackgroundColor(String hexColor) async {
    try {
      final result = await _channel.invokeMethod('setBackgroundColor', {
        'color': hexColor,
      });
      return result;
    } on PlatformException catch (e) {
      print('배경색 설정 실패: ${e.message}');
      return false;
    }
  }

  /// 텍스트 색상 설정
  static Future<bool> setTextColor(String hexColor) async {
    try {
      final result = await _channel.invokeMethod('setTextColor', {
        'color': hexColor,
      });
      return result;
    } on PlatformException catch (e) {
      print('텍스트 색상 설정 실패: ${e.message}');
      return false;
    }
  }

  /// 필요한 권한이 있는지 확인
  static Future<bool> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod('checkPermissions');
      return result;
    } on PlatformException catch (e) {
      print('권한 확인 실패: ${e.message}');
      return false;
    }
  }

  /// 필요한 권한 요청
  static Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod('requestPermissions');
      return result;
    } on PlatformException catch (e) {
      print('권한 요청 실패: ${e.message}');
      return false;
    }
  }
}
