// lib/app/app.dart - محدث بدون onboarding
import 'package:athkar_app/app/routes/app_router.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/app/themes/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


class AthkarApp extends StatelessWidget {
  final bool isDarkMode;
  
  const AthkarApp({
    super.key,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'), // العربية
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // إضافة navigatorKey
      navigatorKey: AppRouter.navigatorKey,
      // استخدام AppRouter
      initialRoute: AppRouter.initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}