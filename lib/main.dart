import 'package:flutter/material.dart';
import 'package:health_controller_app/features/router/router.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HealthControllerApp(),
    ));

class HealthControllerApp extends StatelessWidget {
  const HealthControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: routes,
    );
  }
}
