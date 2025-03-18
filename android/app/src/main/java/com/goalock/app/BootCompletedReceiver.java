package com.goalock.app;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.util.Log;

/**
 * 부팅이 완료되면 잠금화면 서비스를 자동으로 시작하는 리시버
 */
public class BootCompletedReceiver extends BroadcastReceiver {
    private static final String TAG = "BootCompletedReceiver";
    private static final String PREFS_NAME = "GoalockPrefs";
    private static final String KEY_SERVICE_ENABLED = "lockScreenServiceEnabled";

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        if (action == null) return;
        
        Log.d(TAG, "브로드캐스트 수신: " + action);
        
        // 부팅 완료 또는 빠른 부팅 완료 이벤트 처리
        if (Intent.ACTION_BOOT_COMPLETED.equals(action) ||
            "android.intent.action.QUICKBOOT_POWERON".equals(action) ||
            "com.htc.intent.action.QUICKBOOT_POWERON".equals(action)) {
            
            Log.d(TAG, "부팅이 완료되었습니다.");
            startServiceIfEnabled(context);
        } 
        // 사용자가 기기를 언락했을 때의 이벤트 처리
        else if (Intent.ACTION_USER_PRESENT.equals(action)) {
            Log.d(TAG, "사용자가 기기를 언락했습니다.");
            // 필요한 경우 여기서 특별한 처리 수행
        }
    }
    
    private void startServiceIfEnabled(Context context) {
        // 서비스가 활성화되어 있는지 확인
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        boolean isServiceEnabled = prefs.getBoolean(KEY_SERVICE_ENABLED, false);
        
        Log.d(TAG, "서비스 활성화 상태: " + isServiceEnabled);
        
        if (isServiceEnabled) {
            Log.d(TAG, "잠금화면 서비스를 시작합니다.");
            
            // 딜레이를 주어 시스템이 완전히 부팅된 후 서비스 시작
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                Log.e(TAG, "스레드 슬립 중 인터럽트: " + e.getMessage());
            }
            
            // 서비스 시작
            Intent serviceIntent = new Intent(context, LockScreenService.class);
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent);
            } else {
                context.startService(serviceIntent);
            }
            
            Log.d(TAG, "잠금화면 서비스 시작 요청 완료");
        }
    }
} 