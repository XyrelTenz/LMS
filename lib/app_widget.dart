import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      title: 'Library Management System',
    );
  }
}
