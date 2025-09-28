// lib/features/onboarding/widgets/permissions_list.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import '../models/onboarding_data.dart';

class PermissionsList extends StatelessWidget {
  final List<OnboardingPermission> permissions;
  final List<AppPermissionType> grantedPermissions;
  final Function(AppPermissionType)? onPermissionRequest;

  const PermissionsList({
    super.key,
    required this.permissions,
    required this.grantedPermissions,
    this.onPermissionRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: permissions.asMap().entries.map((entry) {
        final index = entry.key;
        final permission = entry.value;
        final isGranted = grantedPermissions.contains(permission.permissionType);
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 20),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: index < permissions.length - 1 ? ThemeConstants.space3 : 0,
                  ),
                  child: _PermissionCard(
                    permission: permission,
                    isGranted: isGranted,
                    onTap: onPermissionRequest != null
                        ? () {
                            HapticFeedback.lightImpact();
                            onPermissionRequest!(permission.permissionType);
                          }
                        : null,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final OnboardingPermission permission;
  final bool isGranted;
  final VoidCallback? onTap;

  const _PermissionCard({
    required this.permission,
    required this.isGranted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        child: AnimatedContainer(
          duration: ThemeConstants.durationNormal,
          padding: const EdgeInsets.all(ThemeConstants.space4),
          decoration: BoxDecoration(
            color: isGranted 
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
            border: Border.all(
              color: isGranted 
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.2),
              width: isGranted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // الأيقونة
              AnimatedContainer(
                duration: ThemeConstants.durationNormal,
                padding: const EdgeInsets.all(ThemeConstants.space3),
                decoration: BoxDecoration(
                  color: isGranted 
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                ),
                child: Icon(
                  permission.icon,
                  color: isGranted ? ThemeConstants.success : Colors.white,
                  size: ThemeConstants.iconMd,
                ),
              ),
              
              const SizedBox(width: ThemeConstants.space4),
              
              // المحتوى
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            permission.title,
                            style: AppTextStyles.label1.copyWith(
                              color: Colors.white,
                              fontWeight: ThemeConstants.semiBold,
                            ),
                          ),
                        ),
                        if (permission.isRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ThemeConstants.space2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ThemeConstants.error,
                              borderRadius: BorderRadius.circular(ThemeConstants.radiusFull),
                            ),
                            child: Text(
                              'مطلوب',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: ThemeConstants.semiBold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: ThemeConstants.space1),
                    
                    Text(
                      permission.description,
                      style: AppTextStyles.body2.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: ThemeConstants.space3),
              
              // حالة الإذن
              AnimatedContainer(
                duration: ThemeConstants.durationNormal,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isGranted 
                      ? ThemeConstants.success
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                  border: Border.all(
                    color: isGranted 
                        ? ThemeConstants.success
                        : Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isGranted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}