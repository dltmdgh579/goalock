import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// 잠금화면 배경화면 관리 서비스
class WallpaperService {
  final WallpaperManagerPlus _wallpaperManager = WallpaperManagerPlus();

  /// 권한 요청 및 확인
  Future<PermissionStatus> requestWallpaperPermission() async {
    // 기본 SET_WALLPAPER 권한 요청
    var status = await Permission.storage.request();
    debugPrint('저장소 권한 상태: $status');

    if (status.isGranted) {
      return status;
    }

    // Android 10 이상에서는 추가 권한 필요
    if (Platform.isAndroid) {
      status = await Permission.manageExternalStorage.request();
      debugPrint('외부 저장소 관리 권한 상태: $status');
    }

    return status;
  }

  /// 목표 텍스트를 포함한 잠금화면 이미지 생성 및 설정
  Future<bool> setGoalWallpaper({
    required String goalText,
    Color backgroundColor = const Color(0xFF4CAF50),
    Color textColor = Colors.white,
    double fontSize = 48,
  }) async {
    try {
      // 디버그 로그 추가
      debugPrint('잠금화면 설정 시작: $goalText');

      // 권한 요청
      final status = await requestWallpaperPermission();
      if (!status.isGranted) {
        debugPrint('필요한 권한이 없습니다: $status');
        return false;
      }

      // 임시 이미지 파일 경로 생성
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/goal_wallpaper.jpg';
      debugPrint('이미지 경로: $imagePath');

      // 이미지 생성
      final file = await _createWallpaperImage(
        goalText: goalText,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: fontSize,
        imagePath: imagePath,
      );

      debugPrint('이미지 생성 완료: ${file.path}, 파일 존재: ${file.existsSync()}');

      // 잠금화면 설정
      final result = await _wallpaperManager.setWallpaper(
        file, // File 객체 직접 전달
        WallpaperManagerPlus.lockScreen,
      );

      debugPrint('잠금화면 설정 결과: $result');
      // 결과가 true이거나 성공 메시지인 경우 성공으로 처리
      return result == true || result.toString().contains("success");
    } catch (e) {
      debugPrint('잠금화면 설정 오류 발생: $e');
      return false;
    }
  }

  /// 목표 텍스트를 포함한 이미지 생성
  Future<File> _createWallpaperImage({
    required String goalText,
    required Color backgroundColor,
    required Color textColor,
    required double fontSize,
    required String imagePath,
  }) async {
    try {
      // 캔버스 생성
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint =
          Paint()
            ..color = backgroundColor
            ..style = PaintingStyle.fill;

      // 화면 크기 (일반적인 모바일 화면 비율)
      const width = 1080.0;
      const height = 1920.0;

      // 배경 그리기
      canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), paint);

      // 텍스트 그리기
      final textPainter = TextPainter(
        text: TextSpan(
          text: goalText.isEmpty ? "목표를 입력하세요" : goalText,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      // 텍스트 레이아웃 계산 및 중앙 배치
      textPainter.layout(maxWidth: width - 80);
      textPainter.paint(
        canvas,
        Offset(
          (width - textPainter.width) / 2,
          (height - textPainter.height) / 2,
        ),
      );

      // 이미지로 변환
      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes == null) {
        throw Exception('이미지 생성에 실패했습니다.');
      }

      // 파일로 저장
      final file = File(imagePath);
      await file.writeAsBytes(pngBytes.buffer.asUint8List());

      debugPrint('이미지 파일 생성 완료: ${file.path}, 크기: ${await file.length()} 바이트');
      return file;
    } catch (e) {
      debugPrint('이미지 생성 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 로드맵 시각화 이미지 생성 및 설정 (향후 구현)
  Future<bool> setRoadmapWallpaper({
    required List<String> steps,
    required int currentStep,
  }) async {
    // TODO: 로드맵 시각화 이미지 생성 및 설정 구현
    return false;
  }
}
