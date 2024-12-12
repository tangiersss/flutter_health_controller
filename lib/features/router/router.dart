import 'package:flutter/material.dart';
import 'package:health_controller_app/features/pages/analyses_screen/analyses_screen.dart';
import 'package:health_controller_app/features/pages/main_screen/main_screen.dart';
import 'package:health_controller_app/features/pages/profile_screen/profile_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const MainScreen(),
  '/analyse': (context) => const AnalysesScreen(),
  '/profile': (context) => const ProfileScreen(),
};
