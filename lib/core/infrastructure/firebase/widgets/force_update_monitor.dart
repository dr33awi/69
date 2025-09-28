// lib/core/infrastructure/firebase/widgets/force_update_monitor.dart

import 'dart:async';
import 'package:athkar_app/core/infrastructure/firebase/remote_config_service.dart';
import 'package:athkar_app/core/infrastructure/firebase/widgets/force_update_screen.dart';
import 'package:flutter/material.dart';


/// مراقب التحديث الإجباري
class ForceUpdateMonitor extends StatefulWidget {
  final Widget child;
  final bool checkOnStart;
  final Duration checkInterval;
  
  const ForceUpdateMonitor({
    super.key,
    required this.child,
    this.checkOnStart = true,
    this.checkInterval = const Duration(minutes: 5),
  });

  @override
  State<ForceUpdateMonitor> createState() => _ForceUpdateMonitorState();
}

class _ForceUpdateMonitorState extends State<ForceUpdateMonitor>
    with WidgetsBindingObserver {
  EnhancedRemoteConfigService? _configService;
  Timer? _checkTimer;
  bool _isForceUpdateRequired = false;
  bool _isCheckingUpdate = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _initializeService();
    
    if (widget.checkOnStart) {
      _scheduleInitialCheck();
    }
    
    _startPeriodicCheck();
  }

  /// تهيئة الخدمة
  void _initializeService() {
    try {
      _configService = EnhancedRemoteConfigService();
      
      // التأكد من تهيئة الخدمة
      _configService!.initialize().then((_) {
        debugPrint('ForceUpdateMonitor: Service initialized');
        if (widget.checkOnStart) {
          _performUpdateCheck();
        }
      }).catchError((e) {
        debugPrint('ForceUpdateMonitor: Service initialization failed: $e');
      });
    } catch (e) {
      debugPrint('ForceUpdateMonitor: Error initializing service: $e');
    }
  }

  /// جدولة الفحص الأولي
  void _scheduleInitialCheck() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _performUpdateCheck();
      }
    });
  }

  /// بدء الفحص الدوري
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(widget.checkInterval, (timer) {
      if (mounted && !_isCheckingUpdate) {
        _performUpdateCheck();
      }
    });
  }

  /// تنفيذ فحص التحديث
  Future<void> _performUpdateCheck() async {
    if (_configService == null || _isCheckingUpdate) return;
    
    try {
      _isCheckingUpdate = true;
      debugPrint('ForceUpdateMonitor: Checking for force update...');
      
      // تحديث الإعدادات من الخادم
      await _configService!.refresh();
      
      // فحص الحاجة للتحديث
      final forceUpdateRequired = _configService!.isForceUpdateRequired();
      
      if (forceUpdateRequired != _isForceUpdateRequired) {
        setState(() {
          _isForceUpdateRequired = forceUpdateRequired;
        });
        
        debugPrint('ForceUpdateMonitor: Force update status changed: $forceUpdateRequired');
        
        if (forceUpdateRequired) {
          _showForceUpdateScreen();
        }
      }
      
    } catch (e) {
      debugPrint('ForceUpdateMonitor: Error checking update: $e');
    } finally {
      _isCheckingUpdate = false;
    }
  }

  /// عرض شاشة التحديث الإجباري
  void _showForceUpdateScreen() {
    if (!mounted) return;
    
    final config = _configService!.getForceUpdateConfig();
    
    // التنقل إلى شاشة التحديث الإجباري
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => EnhancedForceUpdateScreen(
          config: config,
          currentVersion: _configService!.currentAppVersion,
        ),
        settings: const RouteSettings(name: '/force_update'),
      ),
      (route) => false, // إزالة جميع الصفحات السابقة
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // فحص التحديث عند العودة للتطبيق
    if (state == AppLifecycleState.resumed && !_isCheckingUpdate) {
      debugPrint('ForceUpdateMonitor: App resumed, checking for updates...');
      Future.delayed(const Duration(seconds: 1), () {
        _performUpdateCheck();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إذا كان التحديث مطلوباً، عرض شاشة التحديث مباشرة
    if (_isForceUpdateRequired && _configService != null) {
      final config = _configService!.getForceUpdateConfig();
      return EnhancedForceUpdateScreen(
        config: config,
        currentVersion: _configService!.currentAppVersion,
      );
    }
    
    // عرض المحتوى العادي
    return widget.child;
  }
}

/// إضافة لـ BuildContext
extension ForceUpdateExtensions on BuildContext {
  /// فحص التحديث الإجباري يدوياً
  Future<bool> checkForceUpdate() async {
    try {
      final service = EnhancedRemoteConfigService();
      await service.refresh();
      return service.isForceUpdateRequired();
    } catch (e) {
      debugPrint('Error checking force update: $e');
      return false;
    }
  }
  
  /// الحصول على إعدادات التحديث
  ForceUpdateConfig? getForceUpdateConfig() {
    try {
      final service = EnhancedRemoteConfigService();
      return service.getForceUpdateConfig();
    } catch (e) {
      debugPrint('Error getting force update config: $e');
      return null;
    }
  }
}