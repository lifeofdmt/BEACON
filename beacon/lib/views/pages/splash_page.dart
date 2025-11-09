import 'dart:async';

import 'package:beacon/services/gemini_service.dart';
import 'package:beacon/services/quest_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/constants.dart';
import '../../data/notifiers.dart';
import 'auth_layout.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Minimum splash duration so the animation is visible
    const minDuration = Duration(milliseconds: 1500);
    final start = DateTime.now();

    try {
      // Load theme preference
      final prefs = await SharedPreferences.getInstance();
      final bool? storedTheme = prefs.getBool(KConstants.themeModeKey);
      // Update notifier (listenable is read in MaterialApp)
      isDarkModeNotifier.value = storedTheme ?? false;

      // Initialize AI model (non-blocking if already init)
      await GeminiService.instance.initialize();

  // Preload quests
  await QuestService.instance.getQuests();

  // Notifications scheduling removed per request
    } catch (e) {
      // Log and continue to app
      debugPrint('Splash init error: $e');
    }

    // Ensure splash shown at least minDuration
    final elapsed = DateTime.now().difference(start);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    if (!mounted) return;
    // Navigate to main app
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const AuthLayout(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie splash animation
              Lottie.asset(
                'assets/lotties/splash.json',
                height: 220,
                repeat: true,
              ),
              const SizedBox(height: 16),
              // App title or subtle tagline
              Text(
                'BEACON',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              // Progress indicator with subtle styling
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
