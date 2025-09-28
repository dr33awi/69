// lib/features/onboarding/widgets/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import '../models/onboarding_data.dart';
import '../widgets/islamic_pattern_painter.dart';
import '../widgets/features_list.dart';
import '../widgets/permissions_list.dart';

class OnboardingScreenWidget extends StatefulWidget {
  final OnboardingScreen screen;
  final bool isActive;
  final List<AppPermissionType> grantedPermissions;
  final Function(AppPermissionType)? onPermissionRequest;

  const OnboardingScreenWidget({
    super.key,
    required this.screen,
    required this.isActive,
    this.grantedPermissions = const [],
    this.onPermissionRequest,
  });

  @override
  State<OnboardingScreenWidget> createState() => _OnboardingScreenWidgetState();
}

class _OnboardingScreenWidgetState extends State<OnboardingScreenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isActive) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(OnboardingScreenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _animationController.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: widget.screen.gradient,
        ),
      ),
      child: Stack(
        children: [
          // النمط الإسلامي في الخلفية
          Positioned.fill(
            child: CustomPaint(
              painter: IslamicPatternPainter(
                patternType: widget.screen.patternType,
                color: Colors.white,
                opacity: 0.1,
              ),
            ),
          ),

          // المحتوى الرئيسي
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(ThemeConstants.space6),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // الأيقونة والعنوان
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // الأيقونة
                                Container(
                                  padding: const EdgeInsets.all(ThemeConstants.space6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(ThemeConstants.radius3xl),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    widget.screen.icon,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: ThemeConstants.space5),

                                // العنوان
                                Text(
                                  widget.screen.title,
                                  style: AppTextStyles.h1.copyWith(
                                    color: Colors.white,
                                    fontSize: 28,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: ThemeConstants.space3),

                                // العنوان الفرعي
                                Text(
                                  widget.screen.subtitle,
                                  style: AppTextStyles.h4.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: ThemeConstants.space4),

                                // الوصف
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ThemeConstants.space4,
                                  ),
                                  child: Text(
                                    widget.screen.description,
                                    style: AppTextStyles.body1.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      height: 1.6,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // المحتوى (الميزات أو الأذونات)
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              width: double.infinity,
                              child: widget.screen.features != null
                                  ? FeaturesList(features: widget.screen.features!)
                                  : widget.screen.permissions != null
                                      ? PermissionsList(
                                          permissions: widget.screen.permissions!,
                                          grantedPermissions: widget.grantedPermissions,
                                          onPermissionRequest: widget.onPermissionRequest,
                                        )
                                      : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}