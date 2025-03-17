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
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import io.flutter.embedding.android.FlutterActivity;

public class LockScreenService extends Service {
    private static final String TAG = "LockScreenService";
    private static final String PREFS_NAME = "GoalockPrefs";
    private static final String KEY_GOAL_TEXT = "goalText";
    private static final String KEY_BG_COLOR = "backgroundColor";
    private static final String KEY_TEXT_COLOR = "textColor";
    
    // Notification ID & Channel ID
    private static final int NOTIFICATION_ID = 1001;
    private static final String CHANNEL_ID = "goalock_channel";

    private WindowManager windowManager;
    private View lockScreenView;
    private TextView goalTextView;
    private LinearLayout goalLockLayout;
    private String goalText = "";
    private int backgroundColor = Color.GREEN;
    private int textColor = Color.WHITE;
    private KeyguardManager keyguardManager;

    private final BroadcastReceiver screenOffReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (Intent.ACTION_SCREEN_OFF.equals(intent.getAction())) {
                Log.d(TAG, "화면이 꺼졌습니다. 잠금화면을 준비합니다.");
                hideLockScreen(); // 화면이 꺼지면 우선 잠금화면을 제거합니다
            }
        }
    };

    private final BroadcastReceiver screenOnReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (Intent.ACTION_SCREEN_ON.equals(intent.getAction())) {
                Log.d(TAG, "화면이 켜졌습니다. 잠금화면을 표시합니다.");
                // 화면이 켜지자마자 즉시 잠금화면을 표시합니다
                showLockScreen();
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
                hideLockScreen(); // 커스텀 잠금화면도 숨깁니다
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
        
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        keyguardManager = (KeyguardManager) getSystemService(KEYGUARD_SERVICE);
        
        // 설정 로드
        loadSettings();
        
        // 화면 상태 변화 감지를 위한 브로드캐스트 리시버 등록
        IntentFilter screenOffFilter = new IntentFilter(Intent.ACTION_SCREEN_OFF);
        registerReceiver(screenOffReceiver, screenOffFilter);
        
        IntentFilter screenOnFilter = new IntentFilter(Intent.ACTION_SCREEN_ON);
        registerReceiver(screenOnReceiver, screenOnFilter);
        
        // 키가드 상태 변경 수신기 등록
        IntentFilter keyguardFilter = new IntentFilter(Intent.ACTION_USER_PRESENT);
        registerReceiver(keyguardReceiver, keyguardFilter);
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
        backgroundColor = prefs.getInt(KEY_BG_COLOR, Color.GREEN);
        textColor = prefs.getInt(KEY_TEXT_COLOR, Color.WHITE);
        Log.d(TAG, "설정 로드: goalText=" + goalText);
    }

    private void showLockScreen() {
        if (lockScreenView != null) {
            return; // 이미 보여지고 있다면 무시
        }

        try {
            // 레이아웃 인플레이트 - 동적으로 생성
            lockScreenView = createLockScreenView();
            
            // 윈도우 매니저 파라미터 설정 - 최상위 우선순위로 설정
            WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    // 최상위 오버레이 타입 사용
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                    // 기본 잠금화면 위에 표시하는 플래그 설정
                    WindowManager.LayoutParams.FLAG_FULLSCREEN |
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD |
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON |
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON |
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN |
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                    PixelFormat.TRANSLUCENT
            );
            
            params.gravity = Gravity.CENTER;
            
            // 잠금화면 표시
            windowManager.addView(lockScreenView, params);
            Log.d(TAG, "잠금화면 표시됨");
        } catch (Exception e) {
            Log.e(TAG, "잠금화면 표시 실패: " + e.getMessage());
        }
    }
    
    // 동적으로 잠금화면 뷰 생성
    private View createLockScreenView() {
        // 루트 레이아웃 생성
        LinearLayout rootLayout = new LinearLayout(this);
        rootLayout.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT));
        rootLayout.setOrientation(LinearLayout.VERTICAL);
        rootLayout.setGravity(Gravity.CENTER);
        rootLayout.setBackgroundColor(backgroundColor);
        rootLayout.setId(View.generateViewId());
        goalLockLayout = rootLayout;
        
        // 목표 텍스트뷰 생성
        TextView textView = new TextView(this);
        textView.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT));
        textView.setText(goalText);
        textView.setTextColor(textColor);
        textView.setTextSize(24);
        textView.setPadding(16, 16, 16, 16);
        textView.setGravity(Gravity.CENTER);
        textView.setId(View.generateViewId());
        goalTextView = textView;
        
        // 안내 텍스트뷰 생성
        TextView hintTextView = new TextView(this);
        hintTextView.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT));
        hintTextView.setText("오른쪽으로 스와이프하여 잠금화면 넘기기");
        hintTextView.setTextColor(textColor);
        hintTextView.setTextSize(14);
        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) hintTextView.getLayoutParams();
        params.topMargin = 32;
        hintTextView.setLayoutParams(params);
        
        // 뷰 추가
        rootLayout.addView(textView);
        rootLayout.addView(hintTextView);
        
        // 스와이프 이벤트 설정
        rootLayout.setOnTouchListener(new OnSwipeTouchListener(this) {
            @Override
            public void onSwipeRight() {
                hideLockScreen();
            }
        });
        
        return rootLayout;
    }

    private void hideLockScreen() {
        if (lockScreenView != null) {
            try {
                windowManager.removeView(lockScreenView);
                lockScreenView = null;
                Log.d(TAG, "잠금화면 숨김");
            } catch (Exception e) {
                Log.e(TAG, "잠금화면 숨기기 실패: " + e.getMessage());
            }
        }
    }

    public void updateGoalText(String newGoalText) {
        goalText = newGoalText;
        
        // 설정 저장
        SharedPreferences.Editor editor = getSharedPreferences(PREFS_NAME, MODE_PRIVATE).edit();
        editor.putString(KEY_GOAL_TEXT, goalText);
        editor.apply();
        
        // 현재 보여지고 있는 화면 업데이트
        if (goalTextView != null) {
            goalTextView.setText(goalText);
        }
        
        Log.d(TAG, "목표 텍스트 업데이트: " + goalText);
    }

    public void updateColors(int newBackgroundColor, int newTextColor) {
        backgroundColor = newBackgroundColor;
        textColor = newTextColor;
        
        // 설정 저장
        SharedPreferences.Editor editor = getSharedPreferences(PREFS_NAME, MODE_PRIVATE).edit();
        editor.putInt(KEY_BG_COLOR, backgroundColor);
        editor.putInt(KEY_TEXT_COLOR, textColor);
        editor.apply();
        
        // 현재 보여지고 있는 화면 업데이트
        if (goalTextView != null && goalLockLayout != null) {
            goalTextView.setTextColor(textColor);
            goalLockLayout.setBackgroundColor(backgroundColor);
        }
        
        Log.d(TAG, "색상 업데이트됨");
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
                int newBgColor = intent.getIntExtra("backgroundColor", backgroundColor);
                int newTextColor = intent.getIntExtra("textColor", textColor);
                updateColors(newBgColor, newTextColor);
            }
        }
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        
        // 브로드캐스트 리시버 해제
        try {
            unregisterReceiver(screenOffReceiver);
            unregisterReceiver(screenOnReceiver);
            unregisterReceiver(keyguardReceiver);
        } catch (Exception e) {
            Log.e(TAG, "리시버 해제 중 오류: " + e.getMessage());
        }
        
        // 잠금화면이 표시되어 있다면 제거
        hideLockScreen();
        
        Log.d(TAG, "잠금화면 서비스 종료됨");
    }
} 