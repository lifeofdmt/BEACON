import 'package:beacon/views/mobile/auth_service.dart';
import 'package:beacon/views/pages/welcome_page.dart';
import 'package:beacon/views/widget_tree.dart';
import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: authService.value.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        
        if (snapshot.hasData) {
          return const WidgetTree();
        }
        
        return pageIfNotConnected ?? const WelcomePage();
      },
    );
  }
}