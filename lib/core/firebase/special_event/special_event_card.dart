// lib/core/infrastructure/firebase/special_event/special_event_card.dart

import 'package:athkar_app/core/firebase/special_event/modals/special_event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'widgets/event_card_content.dart';
import 'services/event_data_service.dart';

final GetIt _getIt = GetIt.instance;

/// كارد المناسبات الخاصة
class SpecialEventCard extends StatefulWidget {
  const SpecialEventCard({super.key});

  @override
  State<SpecialEventCard> createState() => _SpecialEventCardState();
}

class _SpecialEventCardState extends State<SpecialEventCard> {
  SpecialEventModel _event = SpecialEventModel.empty();
  bool _isLoading = true;
  bool _hasError = false;
  
  late final EventDataService _dataService;
  
  @override
  void initState() {
    super.initState();
    _dataService = EventDataService(_getIt);
    _loadEventData();
  }
  
  Future<void> _loadEventData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      final eventData = await _dataService.fetchEventData();
      
      if (eventData != null) {
        final event = SpecialEventModel.fromMap(eventData);
        
        setState(() {
          _event = event;
          _isLoading = false;
        });
        
        if (event.isValid) {
          debugPrint('✅ Event activated: ${event.title}');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading event: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading || _hasError || !_event.isValid) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      child: EventCardContent(event: _event),
    );
  }
}