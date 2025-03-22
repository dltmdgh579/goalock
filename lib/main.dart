import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goalock/screens/home_screen.dart';
import 'package:goalock/services/storage_service.dart';
import 'package:goalock/services/wallpaper_service.dart';
import 'package:goalock/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const GoalLockApp());
}

class GoalLockApp extends StatelessWidget {
  const GoalLockApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<WallpaperService>(create: (_) => WallpaperService()),
      ],
      child: MaterialApp(
        title: 'GoalLock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
        locale: const Locale('ko', 'KR'),
      ),
    );
  }
}
