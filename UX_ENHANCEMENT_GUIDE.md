# 🎨 تحسين تجربة المستخدم

## 1. Loading States المحسنة

### Shimmer Loading بدلاً من Circular Indicators:

```dart
// lib/app/themes/widgets/loading/shimmer_widgets.dart
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  
  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    
    return Shimmer.fromColors(
      baseColor: context.cardColor,
      highlightColor: context.cardColor.withValues(alpha: 0.3),
      child: child,
    );
  }
}

// Prayer Times Shimmer
class PrayerTimesShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) => 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 120,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// استخدام محسن في الصفحات
Widget _buildPrayerTimesList() {
  return StreamBuilder<List<PrayerTime>>(
    stream: _prayerService.prayerTimesStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const PrayerTimesShimmer();
      }
      
      if (snapshot.hasError) {
        return AppErrorWidget(
          message: snapshot.error.toString(),
          onRetry: () => _prayerService.refresh(),
        );
      }
      
      return PrayerTimesList(times: snapshot.data ?? []);
    },
  );
}
```

## 2. Smooth Animations و Micro-interactions

### Page Transitions محسنة:

```dart
// lib/app/routes/custom_transitions.dart
class SlidePageRoute<T> extends PageRoute<T> {
  final Widget child;
  final SlideDirection direction;
  
  SlidePageRoute({
    required this.child,
    this.direction = SlideDirection.rightToLeft,
    RouteSettings? settings,
  }) : super(settings: settings);
  
  @override
  Color? get barrierColor => null;
  
  @override
  String? get barrierLabel => null;
  
  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
  
  @override
  bool get maintainState => true;
  
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final tween = Tween<Offset>(
      begin: _getBeginOffset(),
      end: Offset.zero,
    );
    
    return SlideTransition(
      position: animation.drive(
        tween.chain(CurveTween(curve: Curves.easeInOutCubic)),
      ),
      child: child,
    );
  }
  
  Offset _getBeginOffset() {
    switch (direction) {
      case SlideDirection.rightToLeft:
        return const Offset(1.0, 0.0);
      case SlideDirection.leftToRight:
        return const Offset(-1.0, 0.0);
      case SlideDirection.topToBottom:
        return const Offset(0.0, -1.0);
      case SlideDirection.bottomToTop:
        return const Offset(0.0, 1.0);
    }
  }
  
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }
}

enum SlideDirection {
  rightToLeft,
  leftToRight,
  topToBottom,
  bottomToTop,
}
```

### Hero Animations للصور والعناصر:

```dart
// في AsmaAllahCard
class AsmaAllahCard extends StatelessWidget {
  final AsmaAllahModel item;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'asma_${item.id}_circle',
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [item.getColor(), item.getColor().withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${item.id}',
                      style: context.titleMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Hero(
                  tag: 'asma_${item.id}_text',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      item.name,
                      style: context.titleLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 3. Responsive Design

### Adaptive Layout:

```dart
// lib/app/themes/responsive/responsive_widget.dart
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 800) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

// استخدام في الصفحات
class PrayerTimesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }
  
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildPrayerTimesList()),
      ],
    );
  }
  
  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(flex: 1, child: _buildSidebar()),
        Expanded(flex: 2, child: _buildMainContent()),
      ],
    );
  }
}
```

## 4. Dark Mode Support المحسن

### Theme Switching مع Animation:

```dart
// lib/app/themes/theme_switcher.dart
class AnimatedThemeSwitcher extends StatefulWidget {
  final Widget child;
  
  const AnimatedThemeSwitcher({
    super.key,
    required this.child,
  });
  
  @override
  State<AnimatedThemeSwitcher> createState() => _AnimatedThemeSwitcherState();
}

class _AnimatedThemeSwitcherState extends State<AnimatedThemeSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: getIt<ThemeNotifier>(),
      builder: (context, themeMode, child) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getGradientColors(themeMode),
                ),
              ),
              child: widget.child,
            );
          },
        );
      },
    );
  }
  
  List<Color> _getGradientColors(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return [
          const Color(0xFF1A1A2E),
          const Color(0xFF16213E),
        ];
      case ThemeMode.light:
      default:
        return [
          Colors.white,
          Colors.grey[50]!,
        ];
    }
  }
}
```

## 5. Accessibility (إمكانية الوصول)

### Screen Reader Support:

```dart
// lib/app/themes/widgets/accessible_widgets.dart
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final String? semanticHint;
  final VoidCallback? onTap;
  
  const AccessibleCard({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.semanticHint,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

// في PrayerTimeCard
class PrayerTimeCard extends StatelessWidget {
  final PrayerTime prayer;
  
  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat.Hm().format(prayer.time);
    final semanticLabel = 'صلاة ${prayer.name}، الوقت ${timeText}';
    final semanticHint = prayer.isNext 
        ? 'الصلاة القادمة' 
        : 'انقر للمزيد من التفاصيل';
    
    return AccessibleCard(
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      onTap: () => _showPrayerDetails(prayer),
      child: ListTile(
        leading: Icon(prayer.icon),
        title: Text(prayer.name),
        subtitle: Text(timeText),
        trailing: prayer.isNext 
            ? Icon(Icons.schedule, color: Colors.green)
            : null,
      ),
    );
  }
}
```

## 6. Pull-to-Refresh المحسن

```dart
// lib/app/themes/widgets/custom_refresh.dart
class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String refreshText;
  
  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshText = 'اسحب للتحديث',
  });
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      backgroundColor: context.cardColor,
      color: ThemeConstants.primary,
      strokeWidth: 3,
      displacement: 60,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  refreshText,
                  style: context.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: child),
        ],
      ),
    );
  }
}
```

## 7. Haptic Feedback

### تحسين التفاعل اللمسي:

```dart
// lib/core/haptics/haptic_service.dart
class HapticService {
  /// ردود الفعل للنجاح
  static void success() {
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
  }
  
  /// ردود الفعل للخطأ
  static void error() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }
  
  /// ردود الفعل للتحديد
  static void selection() {
    HapticFeedback.selectionClick();
  }
  
  /// ردود الفعل خفيفة
  static void light() {
    HapticFeedback.lightImpact();
  }
  
  /// ردود الفعل متوسطة
  static void medium() {
    HapticFeedback.mediumImpact();
  }
}

// استخدام في الأزرار والتفاعلات
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonType type;
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed != null ? () {
        // تحديد نوع Haptic حسب نوع الزر
        switch (type) {
          case ButtonType.primary:
            HapticService.medium();
            break;
          case ButtonType.success:
            HapticService.success();
            break;
          case ButtonType.error:
            HapticService.error();
            break;
          default:
            HapticService.light();
        }
        onPressed!();
      } : null,
      child: child,
    );
  }
}
```

## 8. Smart Notifications

### إشعارات ذكية مع Context:

```dart
// lib/core/notifications/smart_notification_service.dart
class SmartNotificationService {
  /// إشعار ذكي للصلاة
  static Future<void> schedulePrayerNotification(PrayerTime prayer) async {
    final now = DateTime.now();
    final timeDifference = prayer.time.difference(now);
    
    // إشعار قبل 15 دقيقة
    if (timeDifference.inMinutes > 15) {
      await NotificationService.schedule(
        id: prayer.id * 10,
        title: 'تذكير بالصلاة',
        body: 'بقي 15 دقيقة على أذان ${prayer.name}',
        scheduledTime: prayer.time.subtract(const Duration(minutes: 15)),
        data: {
          'type': 'prayer_reminder',
          'prayer_name': prayer.name,
          'time_left': '15',
        },
      );
    }
    
    // إشعار وقت الأذان
    await NotificationService.schedule(
      id: prayer.id,
      title: 'حان وقت ${prayer.name}',
      body: _getPrayerMessage(prayer.name),
      scheduledTime: prayer.time,
      data: {
        'type': 'prayer_time',
        'prayer_name': prayer.name,
      },
    );
  }
  
  static String _getPrayerMessage(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return 'الصلاة خير من النوم';
      case 'الظهر':
        return 'تعال إلى الصلاة، تعال إلى الفلاح';
      case 'العصر':
        return 'والعصر إن الإنسان لفي خسر';
      case 'المغرب':
        return 'اللهم بلغنا ليلة القدر';
      case 'العشاء':
        return 'اللهم أعنا على ذكرك وشكرك وحسن عبادتك';
      default:
        return 'حان وقت الصلاة';
    }
  }
}
```

## الخلاصة:

1. **استخدام Shimmer Loading بدلاً من Loading Circles**
2. **إضافة Hero Animations والانتقالات السلسة**
3. **دعم Responsive Design للأجهزة المختلفة**
4. **تحسين Dark Mode مع الانتقالات**
5. **دعم Accessibility وScreen Readers**
6. **تحسين Pull-to-Refresh**
7. **إضافة Haptic Feedback ذكي**
8. **إشعارات ذكية مع Context مناسب**