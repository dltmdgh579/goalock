package com.goalock.app;

import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "com.goalock.app/lockscreen";
    private static final String PREFS_NAME = "GoalockPrefs";
    private static final String KEY_SERVICE_ENABLED = "lockScreenServiceEnabled";
    private static final String KEY_GOAL_TEXT = "goalText";
    private static final String KEY_BACKGROUND_COLOR = "backgroundColor";
    private static final String KEY_TEXT_COLOR = "textColor";
    
    private static final int REQUEST_CODE_OVERLAY_PERMISSION = 100;
    private MethodChannel.Result pendingResult;
    private String pendingMethodCall;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        
        // Method Channel 설정
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    switch (call.method) {
                        case "startLockScreenService":
                            startLockScreenService(result);
                            break;
                        case "stopLockScreenService":
                            stopLockScreenService(result);
                            break;
                        case "isLockScreenServiceEnabled":
                            checkServiceStatus(result);
                            break;
                        case "setGoalText":
                            String text = call.argument("text");
                            setGoalText(text, result);
                            break;
                        case "setBackgroundColor":
                            String bgColor = call.argument("color");
                            setBackgroundColor(bgColor, result);
                            break;
                        case "setTextColor":
                            String textColor = call.argument("color");
                            setTextColor(textColor, result);
                            break;
                        case "checkPermissions":
                            checkPermissions(result);
                            break;
                        case "requestPermissions":
                            pendingResult = result;
                            pendingMethodCall = "requestPermissions";
                            requestOverlayPermission();
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                }
            );
    }
    
    // 잠금화면 서비스 시작
    private void startLockScreenService(MethodChannel.Result result) {
        if (!Settings.canDrawOverlays(this)) {
            pendingResult = result;
            pendingMethodCall = "startLockScreenService";
            requestOverlayPermission();
            return;
        }
        
        if (isServiceRunning(LockScreenService.class)) {
            Log.d(TAG, "서비스가 이미 실행 중입니다.");
            result.success(true);
            return;
        }
        
        // 설정 저장
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        prefs.edit().putBoolean(KEY_SERVICE_ENABLED, true).apply();
        
        // 서비스 시작
        Intent intent = new Intent(this, LockScreenService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent);
        } else {
            startService(intent);
        }
        
        Log.d(TAG, "잠금화면 서비스를 시작했습니다.");
        result.success(true);
    }
    
    // 잠금화면 서비스 중지
    private void stopLockScreenService(MethodChannel.Result result) {
        // 설정 저장
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        prefs.edit().putBoolean(KEY_SERVICE_ENABLED, false).apply();
        
        // 서비스 중지
        Intent intent = new Intent(this, LockScreenService.class);
        stopService(intent);
        
        Log.d(TAG, "잠금화면 서비스를 중지했습니다.");
        result.success(true);
    }
    
    // 서비스 상태 확인
    private void checkServiceStatus(MethodChannel.Result result) {
        boolean isRunning = isServiceRunning(LockScreenService.class);
        Log.d(TAG, "서비스 실행 상태: " + isRunning);
        result.success(isRunning);
    }
    
    // 목표 텍스트 설정
    private void setGoalText(String text, MethodChannel.Result result) {
        if (text == null) {
            result.error("INVALID_ARGUMENT", "텍스트가 null입니다", null);
            return;
        }
        
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        prefs.edit().putString(KEY_GOAL_TEXT, text).apply();
        
        Log.d(TAG, "목표 텍스트 설정: " + text);
        result.success(true);
    }
    
    // 배경색 설정
    private void setBackgroundColor(String hexColor, MethodChannel.Result result) {
        if (hexColor == null) {
            result.error("INVALID_ARGUMENT", "색상이 null입니다", null);
            return;
        }
        
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        prefs.edit().putString(KEY_BACKGROUND_COLOR, hexColor).apply();
        
        Log.d(TAG, "배경색 설정: " + hexColor);
        result.success(true);
    }
    
    // 텍스트 색상 설정
    private void setTextColor(String hexColor, MethodChannel.Result result) {
        if (hexColor == null) {
            result.error("INVALID_ARGUMENT", "색상이 null입니다", null);
            return;
        }
        
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        prefs.edit().putString(KEY_TEXT_COLOR, hexColor).apply();
        
        Log.d(TAG, "텍스트 색상 설정: " + hexColor);
        result.success(true);
    }
    
    // 권한 확인
    private void checkPermissions(MethodChannel.Result result) {
        boolean hasOverlayPermission = Settings.canDrawOverlays(this);
        Log.d(TAG, "오버레이 권한 상태: " + hasOverlayPermission);
        result.success(hasOverlayPermission);
    }
    
    // 오버레이 권한 요청
    private void requestOverlayPermission() {
        Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:" + getPackageName()));
        startActivityForResult(intent, REQUEST_CODE_OVERLAY_PERMISSION);
    }
    
    // 서비스 실행 상태 확인
    private boolean isServiceRunning(Class<?> serviceClass) {
        ActivityManager manager = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        if (manager != null) {
            for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
                if (serviceClass.getName().equals(service.service.getClassName())) {
                    return true;
                }
            }
        }
        return false;
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (requestCode == REQUEST_CODE_OVERLAY_PERMISSION) {
            if (Settings.canDrawOverlays(this)) {
                Log.d(TAG, "오버레이 권한 획득 성공");
                
                if (pendingResult != null) {
                    if ("requestPermissions".equals(pendingMethodCall)) {
                        pendingResult.success(true);
                    } else if ("startLockScreenService".equals(pendingMethodCall)) {
                        startLockScreenService(pendingResult);
                    }
                    pendingResult = null;
                    pendingMethodCall = null;
                }
            } else {
                Log.d(TAG, "오버레이 권한 획득 실패");
                if (pendingResult != null) {
                    pendingResult.success(false);
                    pendingResult = null;
                    pendingMethodCall = null;
                }
            }
        } else {
            super.onActivityResult(requestCode, resultCode, data);
        }
    }
} 