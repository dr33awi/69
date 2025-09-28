// lib/features/onboarding/models/onboarding_data.dart
import 'package:flutter/material.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';

class OnboardingScreen {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<String>? features;
  final List<OnboardingPermission>? permissions;
  final String patternType;

  const OnboardingScreen({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    this.features,
    this.permissions,
    required this.patternType,
  });
}

class OnboardingPermission {
  final IconData icon;
  final String title;
  final String description;
  final bool isRequired;
  final AppPermissionType permissionType;

  const OnboardingPermission({
    required this.icon,
    required this.title,
    required this.description,
    required this.isRequired,
    required this.permissionType,
  });
}
