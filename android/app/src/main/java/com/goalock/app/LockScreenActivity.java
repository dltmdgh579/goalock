package com.goalock.app;

import android.app.KeyguardManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

public class LockScreenActivity extends AppCompatActivity {
    private static final String TAG = "LockScreenActivity";
    private static final String PREFS_NAME = "GoalockPrefs";
    private static final String KEY_GOAL_TEXT = "goalText";
    private static final String KEY_BG_COLOR = "backgroundColor";
    private static final String KEY_TEXT_COLOR = "textColor";

    private KeyguardManager keyguardManager;
    private String goalText = "목표를 설정해주세요";
    private int backgroundColor = Color.GREEN;
    private int textColor = Color.WHITE;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "LockScreenActivity 생성됨");

        // Android 8.0 이상에서는 새로운 방법으로 잠금화면 위에 표시
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true);
            setTurnScreenOn(true);
            
            // Android 10 이상에서는 키가드를 직접 비활성화 가능
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // 키가드 비활성화하지 않음 - 기본 잠금화면이 나오도록 설정
                // setKeyguardLocked(false); 호출하지 않음
            }
        } else {
            // 과거 버전 호환성을 위한 코드
            getWindow().addFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON |
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    // FLAG_DISMISS_KEYGUARD 플래그 제거 - 시스템 키가드를 유지
            );
        }

        // KeyguardManager 초기화
        keyguardManager = (KeyguardManager) getSystemService(Context.KEYGUARD_SERVICE);
        
        // API 26 이상에서 키가드 비활성화하는 코드 제거
        // 기본 잠금화면이 표시되도록 하기 위해 키가드를 해제하지 않음

        // 전체화면으로 표시
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE |
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
                View.SYSTEM_UI_FLAG_FULLSCREEN |
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        );

        // 설정 로드
        loadSettings();

        // 동적으로 레이아웃 생성 및 표시
        setContentView(createLockScreenView());
    }

    private void loadSettings() {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        
        // 목표 텍스트 로드
        goalText = prefs.getString(KEY_GOAL_TEXT, "목표를 설정해주세요");
        
        // 색상 로드
        try {
            String bgColorStr = prefs.getString(KEY_BG_COLOR, "#FF4CAF50");
            if (bgColorStr != null && !bgColorStr.isEmpty()) {
                // # 문자 제거 후 HEX 색상 코드를 int로 변환
                backgroundColor = Color.parseColor(bgColorStr);
            }
            
            String textColorStr = prefs.getString(KEY_TEXT_COLOR, "#FFFFFFFF");
            if (textColorStr != null && !textColorStr.isEmpty()) {
                textColor = Color.parseColor(textColorStr);
            }
        } catch (IllegalArgumentException e) {
            Log.e(TAG, "색상 파싱 오류: " + e.getMessage());
            // 오류 발생 시 기본 색상 사용
            backgroundColor = Color.GREEN;
            textColor = Color.WHITE;
        }
        
        Log.d(TAG, "설정 로드: goalText=" + goalText + ", bgColor=" + backgroundColor + ", textColor=" + textColor);
    }

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
        
        // 안내 텍스트뷰 생성
        TextView hintTextView = new TextView(this);
        hintTextView.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT));
        
        // 기본 잠금화면 사용 안내 메시지 추가
        String hint = keyguardManager.isKeyguardSecure() ?
                "스와이프하여 시스템 잠금화면으로 이동" :
                "스와이프하여 잠금화면 해제";
        
        hintTextView.setText(hint);
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
                // 오른쪽으로 스와이프하면 액티비티 종료
                finish();
            }
            
            @Override
            public void onSwipeLeft() {
                // 왼쪽으로 스와이프해도 액티비티 종료
                finish();
            }
            
            @Override
            public void onSwipeUp() {
                // 위로 스와이프해도 액티비티 종료
                finish();
            }
            
            @Override
            public void onSwipeDown() {
                // 아래로 스와이프해도 액티비티 종료
                finish();
            }
        });
        
        return rootLayout;
    }

    @Override
    public void onBackPressed() {
        // 뒤로가기 버튼 무시 (사용자가 잠금화면을 우회할 수 없도록)
        // super.onBackPressed(); // 호출하지 않음
    }

    @Override
    protected void onResume() {
        super.onResume();
        // 키가드 해제 코드 제거 - 시스템 잠금화면이 나오도록 설정
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "LockScreenActivity 소멸됨");
    }
} 