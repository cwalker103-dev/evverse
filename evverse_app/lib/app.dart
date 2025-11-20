import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/theme.dart';

class EvverseApp extends StatelessWidget {
  const EvverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Evverse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}