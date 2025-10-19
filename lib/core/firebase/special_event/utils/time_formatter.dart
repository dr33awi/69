// lib/core/infrastructure/firebase/widgets/special_event/utils/time_formatter.dart

/// مساعد تنسيق الوقت والتاريخ بالعربية
class TimeFormatter {
  /// تنسيق الوقت المتبقي
  static String formatRemainingTime(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    
    // أيام
    if (days > 30) {
      final months = (days / 30).floor();
      return 'متبقي $months ${_getMonthText(months)}';
    } else if (days > 0) {
      return 'متبقي $days ${_getDayText(days)}';
    }
    
    // ساعات
    else if (hours > 0) {
      return 'متبقي $hours ${_getHourText(hours)}';
    }
    
    // دقائق
    else if (minutes > 0) {
      return 'متبقي $minutes ${_getMinuteText(minutes)}';
    }
    
    // أقل من دقيقة
    else {
      return 'ينتهي قريباً';
    }
  }
  
  /// تنسيق التاريخ الكامل
  static String formatDate(DateTime date) {
    const arabicMonths = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    
    final day = date.day;
    final month = arabicMonths[date.month - 1];
    final year = date.year;
    
    return '$day $month $year';
  }
  
  /// تنسيق التاريخ القصير
  static String formatShortDate(DateTime date) {
    const arabicMonths = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    
    final day = date.day;
    final month = arabicMonths[date.month - 1];
    
    return '$day $month';
  }
  
  /// تنسيق الوقت
  static String formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$hour12:$minute $period';
  }
  
  /// الحصول على نص الفترة النسبية
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) {
      // في الماضي
      final positiveDiff = difference.abs();
      if (positiveDiff.inDays > 365) {
        final years = (positiveDiff.inDays / 365).floor();
        return 'منذ $years ${_getYearText(years)}';
      } else if (positiveDiff.inDays > 30) {
        final months = (positiveDiff.inDays / 30).floor();
        return 'منذ $months ${_getMonthText(months)}';
      } else if (positiveDiff.inDays > 0) {
        return 'منذ ${positiveDiff.inDays} ${_getDayText(positiveDiff.inDays)}';
      } else if (positiveDiff.inHours > 0) {
        return 'منذ ${positiveDiff.inHours} ${_getHourText(positiveDiff.inHours)}';
      } else if (positiveDiff.inMinutes > 0) {
        return 'منذ ${positiveDiff.inMinutes} ${_getMinuteText(positiveDiff.inMinutes)}';
      } else {
        return 'الآن';
      }
    } else {
      // في المستقبل
      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return 'بعد $years ${_getYearText(years)}';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return 'بعد $months ${_getMonthText(months)}';
      } else if (difference.inDays > 0) {
        return 'بعد ${difference.inDays} ${_getDayText(difference.inDays)}';
      } else if (difference.inHours > 0) {
        return 'بعد ${difference.inHours} ${_getHourText(difference.inHours)}';
      } else if (difference.inMinutes > 0) {
        return 'بعد ${difference.inMinutes} ${_getMinuteText(difference.inMinutes)}';
      } else {
        return 'قريباً';
      }
    }
  }
  
  // ==================== مساعدات خاصة للغة العربية ====================
  
  /// نص السنة حسب العدد
  static String _getYearText(int count) {
    if (count == 1) return 'سنة';
    if (count == 2) return 'سنتين';
    if (count >= 3 && count <= 10) return 'سنوات';
    return 'سنة';
  }
  
  /// نص الشهر حسب العدد
  static String _getMonthText(int count) {
    if (count == 1) return 'شهر';
    if (count == 2) return 'شهرين';
    if (count >= 3 && count <= 10) return 'أشهر';
    return 'شهر';
  }
  
  /// نص اليوم حسب العدد
  static String _getDayText(int count) {
    if (count == 1) return 'يوم';
    if (count == 2) return 'يومين';
    if (count >= 3 && count <= 10) return 'أيام';
    return 'يوم';
  }
  
  /// نص الساعة حسب العدد
  static String _getHourText(int count) {
    if (count == 1) return 'ساعة';
    if (count == 2) return 'ساعتين';
    if (count >= 3 && count <= 10) return 'ساعات';
    return 'ساعة';
  }
  
  /// نص الدقيقة حسب العدد
  static String _getMinuteText(int count) {
    if (count == 1) return 'دقيقة';
    if (count == 2) return 'دقيقتين';
    if (count >= 3 && count <= 10) return 'دقائق';
    return 'دقيقة';
  }
}