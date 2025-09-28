// lib/features/onboarding/widgets/features_list.dart
import 'package:flutter/material.dart';
import 'package:athkar_app/app/themes/app_theme.dart';

class FeaturesList extends StatelessWidget {
  final List<String> features;

  const FeaturesList({
    super.key,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        
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
                    bottom: index < features.length - 1 ? ThemeConstants.space3 : 0,
                  ),
                  padding: const EdgeInsets.all(ThemeConstants.space4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ThemeConstants.space2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: ThemeConstants.iconSm,
                        ),
                      ),
                      ThemeConstants.space3.w,
                      Expanded(
                        child: Text(
                          feature,
                          style: AppTextStyles.body1.copyWith(
                            color: Colors.white,
                            fontWeight: ThemeConstants.medium,
                          ),
                        ),
                      ),
                    ],
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