package com.goalock.app;

import android.content.Intent;
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

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "com.goalock.app/lockscreen";
    private static final int OVERLAY_PERMISSION_REQUEST_CODE = 1234;

    private MethodChannel methodChannel;
    private boolean pendingMethodCall = false;
    private MethodCall lastMethodCall;
    private Result lastMethodResult;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        methodChannel.setMethodCallHandler(new MethodCallHandler() {
            @Override
            public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
                switch (call.method) {
                    case "requestPermissions":
                        handleRequestPermissions(result);
                        break;
                    case "enableLockScreenService":
                        handleEnableLockScreenService(call, result);
                        break;
                    case "disableLockScreenService":
                        handleDisableLockScreenService(result);
                        break;
                    case "updateGoalText":
                        handleUpdateGoalText(call, result);
                        break;
                    default:
                        result.notImplemented();
                        break;
                }
            }
        });
    }

    private void handleRequestPermissions(Result result) {
        // Android 6.0 (API 23) 이상에서는 오버레이 권한이 필요
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                pendingMethodCall = true;
                lastMethodCall = new MethodCall("requestPermissions", null);
                lastMethodResult = result;

                Intent intent = new Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:" + getPackageName())
                );
                startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE);
            } else {
                result.success(true);
            }
        } else {
            // API 23 미만에서는 권한이 필요 없음
            result.success(true);
        }
    }

    private void handleEnableLockScreenService(MethodCall call, Result result) {
        // 오버레이 권한 확인
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                pendingMethodCall = true;
                lastMethodCall = call;
                lastMethodResult = result;

                Intent intent = new Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:" + getPackageName())
                );
                startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE);
                return;
            }
        }

        try {
            // 서비스 시작
            String goalText = call.argument("goalText");
            Long backgroundColor = call.argument("backgroundColor");
            Long textColor = call.argument("textColor");

            Intent serviceIntent = new Intent(this, LockScreenService.class);
            
            if (goalText != null) {
                serviceIntent.setAction("UPDATE_GOAL");
                serviceIntent.putExtra("goalText", goalText);
            }
            
            if (backgroundColor != null && textColor != null) {
                serviceIntent.setAction("UPDATE_COLORS");
                serviceIntent.putExtra("backgroundColor", backgroundColor.intValue());
                serviceIntent.putExtra("textColor", textColor.intValue());
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent);
            } else {
                startService(serviceIntent);
            }
            
            Log.d(TAG, "잠금화면 서비스가 시작되었습니다.");
            result.success(true);
        } catch (Exception e) {
            Log.e(TAG, "잠금화면 서비스 시작 실패: " + e.getMessage());
            result.error("SERVICE_START_ERROR", "잠금화면 서비스를 시작할 수 없습니다.", e.getMessage());
        }
    }

    private void handleDisableLockScreenService(Result result) {
        try {
            // 서비스 종료
            Intent serviceIntent = new Intent(this, LockScreenService.class);
            stopService(serviceIntent);
            
            Log.d(TAG, "잠금화면 서비스가 중지되었습니다.");
            result.success(true);
        } catch (Exception e) {
            Log.e(TAG, "잠금화면 서비스 중지 실패: " + e.getMessage());
            result.error("SERVICE_STOP_ERROR", "잠금화면 서비스를 중지할 수 없습니다.", e.getMessage());
        }
    }

    private void handleUpdateGoalText(MethodCall call, Result result) {
        try {
            String goalText = call.argument("goalText");
            
            if (goalText == null) {
                result.error("INVALID_ARGUMENT", "목표 텍스트가 null입니다.", null);
                return;
            }
            
            Intent serviceIntent = new Intent(this, LockScreenService.class);
            serviceIntent.setAction("UPDATE_GOAL");
            serviceIntent.putExtra("goalText", goalText);
            
            startService(serviceIntent);
            
            Log.d(TAG, "목표 텍스트가 업데이트 되었습니다: " + goalText);
            result.success(true);
        } catch (Exception e) {
            Log.e(TAG, "목표 텍스트 업데이트 실패: " + e.getMessage());
            result.error("UPDATE_GOAL_ERROR", "목표 텍스트를 업데이트할 수 없습니다.", e.getMessage());
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        
        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (Settings.canDrawOverlays(this)) {
                    if (pendingMethodCall && lastMethodCall != null && lastMethodResult != null) {
                        if ("requestPermissions".equals(lastMethodCall.method)) {
                            lastMethodResult.success(true);
                        } else if ("enableLockScreenService".equals(lastMethodCall.method)) {
                            handleEnableLockScreenService(lastMethodCall, lastMethodResult);
                        }
                        
                        pendingMethodCall = false;
                        lastMethodCall = null;
                        lastMethodResult = null;
                    }
                } else {
                    Toast.makeText(this, "오버레이 권한이 필요합니다.", Toast.LENGTH_SHORT).show();
                    if (lastMethodResult != null) {
                        lastMethodResult.error("PERMISSION_DENIED", "오버레이 권한이 거부되었습니다.", null);
                        lastMethodResult = null;
                    }
                }
            }
        }
    }
} 