// مثال لإضافة Force Update Checker في main.dart

/*
// 1. إضافة الاستيراد في أعلى الملف:
import 'core/firebase/widgets/force_update_checker.dart';

// 2. في initState من _AthkarAppState، أضف الفحص:

@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addObserver(this);
  
  _initializeConfigManager();
  _scheduleInitialPermissionCheck();
  _processPendingNotificationIfAny();
  _monitorConnectivity();
  
  // ✅ إضافة فحص Force Update
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && !_isOfflineMode) {
      ForceUpdateChecker.check(context);
    }
  });
  
  // عرض رسالة الوضع Offline إذا لزم الأمر
  if (_isOfflineMode && !_hasShownOfflineMessage) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOfflineMessage();
    });
  }
}

// 3. في didChangeAppLifecycleState، أضف الفحص عند العودة للتطبيق:

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _processPendingNotificationIfAny();
    
    // فحص الاتصال عند العودة للتطبيق
    _checkAndUpdateConnectivity();
    
    // ✅ فحص Force Update عند العودة للتطبيق
    if (!_isOfflineMode) {
      ForceUpdateChecker.check(context);
    }
  }
}

// 4. أو استخدم الطريقة الأسهل: Widget wrapper

@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<ThemeMode>(
    valueListenable: getIt<ThemeNotifier>(),
    builder: (context, themeMode, _) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) {
          return MaterialApp(
            title: 'ذكرني',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorKey: AppRouter.navigatorKey,
            home: _buildInitialScreen(),
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) {
              // ✅ إضافة Force Update Checker هنا
              return ForceUpdateChecker.widget(
                child: PermissionCheckWidget(
                  showWarningCard: true,
                  child: child ?? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

*/
