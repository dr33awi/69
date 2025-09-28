// lib/features/onboarding/widgets/onboarding_page.dart
import 'package:flutter/material.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/themes/widgets/core/islamic_pattern_painter.dart';
import '../models/onboarding_item.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final bool isLastPage;
  final VoidCallback onNext;
  final bool isProcessing;

  const OnboardingPage({
    super.key,
    required this.item,
    required this.isLastPage,
    required this.onNext,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // النمط الإسلامي في الخلفية
          Positioned.fill(
            child: CustomPaint(
              painter: IslamicPatternPainter(
                rotation: 0,
                color: Colors.white,
                opacity: 0.1,
                patternType: PatternType.standard,
              ),
            ),
          ),
          
          // المحتوى الرئيسي
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  
                  // الصورة/الأيقونة
                  _buildImage(),
                  
                  const SizedBox(height: 48),
                  
                  // العنوان الرئيسي
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // العنوان الفرعي
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // الوصف
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // زر المتابعة
                  _buildActionButton(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          _getIconForPage(),
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  IconData _getIconForPage() {
    // يمكن تخصيص الأيقونات حسب المحتوى
    switch (item.title) {
      case 'مرحباً بك في':
        return Icons.mosque;
      case 'أذكار وأدعية':
        return Icons.menu_book_rounded;
      case 'أوقات الصلاة':
        return Icons.access_time_rounded;
      case 'القبلة والتسبيح':
        return Icons.explore_rounded;
      case 'أذونات مطلوبة':
        return Icons.security_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isProcessing ? null : onNext,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            alignment: Alignment.center,
            child: isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastPage ? 'ابدأ الآن' : 'التالي',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLastPage ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}