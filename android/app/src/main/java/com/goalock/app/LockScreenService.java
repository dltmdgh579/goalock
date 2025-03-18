package com.goalock.app;

import android.app.KeyguardManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Build;
import android.os.IBinder;
import android.os.PowerManager;
import android.util.Log;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import io.flutter.embedding.android.FlutterActivity;

public class LockScreenService extends Service {
    private static final String TAG = "LockScreenService";
    private static final String PREFS_NAME = "GoalockPrefs";
    private static final String KEY_GOAL_TEXT = "goalText";
    private static final String KEY_BG_COLOR = "backgroundColor";
    private static final String KEY_TEXT_COLOR = "textColor";
    private static final String KEY_SERVICE_ENABLED = "lockScreenServiceEnabled";
    
    // Notification ID & Channel ID
    private static final int NOTIFICATION_ID = 1001;
    private static final String CHANNEL_ID = "goalock_channel";

    private KeyguardManager keyguardManager;
    private PowerManager powerManager;
    private PowerManager.WakeLock wakeLock;
    private boolean isServiceRunning = false;
    private String goalText = "";
    private int backgroundColor = Color.GREEN;
    private int textColor = Color.WHITE;

    private final BroadcastReceiver screenOffReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (Intent.ACTION_SCREEN_OFF.equals(intent.getAction())) {
                Log.d(TAG, "화면이 꺼졌습니다. 다음 화면 켜짐을 준비합니다.");
                // 화면이 꺼지면 특별한 처리 없음, 다음 켜짐 이벤트를 기다림
            }
        }
    };

    private final BroadcastReceiver screenOnReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (Intent.ACTION_SCREEN_ON.equals(intent.getAction())) {
                Log.d(TAG, "화면이 켜졌습니다. 잠금화면 액티비티를 시작합니다.");
                showLockScreenActivity();
            }
        }
    };
    
    // 키가드 상태 변경 수신기 추가
    private final BroadcastReceiver keyguardReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (Intent.ACTION_USER_PRESENT.equals(intent.getAction())) {
                // 사용자가 기본 잠금화면을 해제했을 때 호출됩니다
                Log.d(TAG, "사용자가 기본 잠금화면을 해제했습니다.");
            }
        }
    };

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "잠금화면 서비스 시작됨");
        
        // Android 8.0 이상에서는 Foreground Service 필요
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel();
            startForeground(NOTIFICATION_ID, createNotification());
        }
        
        keyguardManager = (KeyguardManager) getSystemService(KEYGUARD_SERVICE);
        powerManager = (PowerManager) getSystemService(POWER_SERVICE);
        
        // 화면 깨우기 위한 WakeLock 설정
        wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK | 
                PowerManager.ACQUIRE_CAUSES_WAKEUP | 
                PowerManager.ON_AFTER_RELEASE, 
                "goalock:wakelock"
        );
        
        // 설정 로드
        loadSettings();
        
        // 서비스 활성화 상태 저장
        saveServiceState(true);
        
        // 화면 상태 변화 감지를 위한 브로드캐스트 리시버 등록
        IntentFilter screenOffFilter = new IntentFilter(Intent.ACTION_SCREEN_OFF);
        registerReceiver(screenOffReceiver, screenOffFilter);
        
        IntentFilter screenOnFilter = new IntentFilter(Intent.ACTION_SCREEN_ON);
        registerReceiver(screenOnReceiver, screenOnFilter);
        
        // 키가드 상태 변경 수신기 등록
        IntentFilter keyguardFilter = new IntentFilter(Intent.ACTION_USER_PRESENT);
        registerReceiver(keyguardReceiver, keyguardFilter);
        
        isServiceRunning = true;
    }
    
    private void saveServiceState(boolean enabled) {
        SharedPreferences.Editor editor = getSharedPreferences(PREFS_NAME, MODE_PRIVATE).edit();
        editor.putBoolean(KEY_SERVICE_ENABLED, enabled);
        editor.apply();
        Log.d(TAG, "서비스 상태 저장: " + enabled);
    }
    
    // 알림 채널 생성 (Android 8.0 이상 필수)
    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "GoalLock Service",
                    NotificationManager.IMPORTANCE_LOW
            );
            
            channel.setDescription("목표 잠금화면 서비스를 위한 알림 채널");
            channel.setSound(null, null);
            channel.enableLights(false);
            channel.enableVibration(false);
            
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(channel);
            
            Log.d(TAG, "알림 채널 생성됨");
        }
    }
    
    // Foreground Service용 알림 생성
    private Notification createNotification() {
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent;
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            pendingIntent = PendingIntent.getActivity(
                    this,
                    0,
                    notificationIntent,
                    PendingIntent.FLAG_IMMUTABLE
            );
        } else {
            pendingIntent = PendingIntent.getActivity(
                    this,
                    0,
                    notificationIntent,
                    0
            );
        }
        
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setContentTitle("GoalLock 실행 중")
                .setContentText("목표 잠금화면 서비스가 활성화되어 있습니다")
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true);
                
        return builder.build();
    }

    private void loadSettings() {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        goalText = prefs.getString(KEY_GOAL_TEXT, "목표를 설정해주세요");
        
        try {
            String bgColorStr = prefs.getString(KEY_BG_COLOR, "#FF4CAF50");
            if (bgColorStr != null && !bgColorStr.isEmpty()) {
                backgroundColor = Color.parseColor(bgColorStr);
            }
            
            String textColorStr = prefs.getString(KEY_TEXT_COLOR, "#FFFFFFFF");
            if (textColorStr != null && !textColorStr.isEmpty()) {
                textColor = Color.parseColor(textColorStr);
            }
        } catch (IllegalArgumentException e) {
            Log.e(TAG, "색상 파싱 오류: " + e.getMessage());
            backgroundColor = Color.GREEN;
            textColor = Color.WHITE;
        }
        
        Log.d(TAG, "설정 로드: goalText=" + goalText + ", bgColor=" + backgroundColor + ", textColor=" + textColor);
    }

    // LockScreenActivity를 시작하는 메서드
    private void showLockScreenActivity() {
        if (!isServiceRunning) {
            return;
        }
        
        try {
            // 화면이 꺼져 있으면 켜도록 WakeLock 획득
            if (!powerManager.isInteractive()) {
                wakeLock.acquire(10*60*1000L); // 10분 동안 WakeLock 유지 (안전장치)
            }
            
            // 잠금화면 액티비티 시작
            Intent lockIntent = new Intent(this, LockScreenActivity.class);
            lockIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK |
                             Intent.FLAG_ACTIVITY_SINGLE_TOP |
                             Intent.FLAG_ACTIVITY_CLEAR_TOP);
            
            // 활동 시작
            startActivity(lockIntent);
            Log.d(TAG, "잠금화면 액티비티 시작됨");
            
            // WakeLock 해제
            if (wakeLock.isHeld()) {
                wakeLock.release();
            }
        } catch (Exception e) {
            Log.e(TAG, "잠금화면 액티비티 시작 실패: " + e.getMessage());
            
            // WakeLock 해제 (예외 발생 시에도)
            if (wakeLock != null && wakeLock.isHeld()) {
                wakeLock.release();
            }
        }
    }

    public void updateGoalText(String newGoalText) {
        goalText = newGoalText;
        
        // 설정 저장
        SharedPreferences.Editor editor = getSharedPreferences(PREFS_NAME, MODE_PRIVATE).edit();
        editor.putString(KEY_GOAL_TEXT, goalText);
        editor.apply();
        
        Log.d(TAG, "목표 텍스트 업데이트: " + goalText);
    }

    public void updateColors(String newBackgroundColor, String newTextColor) {
        try {
            backgroundColor = Color.parseColor(newBackgroundColor);
            textColor = Color.parseColor(newTextColor);
            
            // 설정 저장
            SharedPreferences.Editor editor = getSharedPreferences(PREFS_NAME, MODE_PRIVATE).edit();
            editor.putString(KEY_BG_COLOR, newBackgroundColor);
            editor.putString(KEY_TEXT_COLOR, newTextColor);
            editor.apply();
            
            Log.d(TAG, "색상 업데이트됨: bg=" + newBackgroundColor + ", text=" + newTextColor);
        } catch (IllegalArgumentException e) {
            Log.e(TAG, "색상 파싱 오류: " + e.getMessage());
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            String action = intent.getAction();
            if ("UPDATE_GOAL".equals(action)) {
                String newGoalText = intent.getStringExtra("goalText");
                if (newGoalText != null) {
                    updateGoalText(newGoalText);
                }
            } else if ("UPDATE_COLORS".equals(action)) {
                String newBgColor = intent.getStringExtra("backgroundColor");
                String newTextColor = intent.getStringExtra("textColor");
                if (newBgColor != null && newTextColor != null) {
                    updateColors(newBgColor, newTextColor);
                }
            }
        }
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        
        // 서비스 비활성화 상태 저장
        saveServiceState(false);
        
        // 브로드캐스트 리시버 해제
        try {
            unregisterReceiver(screenOffReceiver);
            unregisterReceiver(screenOnReceiver);
            unregisterReceiver(keyguardReceiver);
        } catch (Exception e) {
            Log.e(TAG, "리시버 해제 중 오류: " + e.getMessage());
        }
        
        // WakeLock 해제 확인
        if (wakeLock != null && wakeLock.isHeld()) {
            wakeLock.release();
        }
        
        isServiceRunning = false;
        Log.d(TAG, "잠금화면 서비스 종료됨");
    }
} 