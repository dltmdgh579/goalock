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
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            Log.d(TAG, "부팅이 완료되었습니다.");
            
            // 서비스가 활성화되어 있는지 확인
            SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            boolean isServiceEnabled = prefs.getBoolean(KEY_SERVICE_ENABLED, false);
            
            if (isServiceEnabled) {
                Log.d(TAG, "잠금화면 서비스를 시작합니다.");
                Intent serviceIntent = new Intent(context, LockScreenService.class);
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent);
                } else {
                    context.startService(serviceIntent);
                }
            }
        }
    }
} 