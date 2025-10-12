// lib/features/settings/widgets/permissions/quick_stat_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// إحصائية سريعة في بطاقة الأذونات
class QuickStatWidget extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const QuickStatWidget({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}