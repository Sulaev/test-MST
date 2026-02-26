import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/onboarding/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/meditation_generator/meditation_generator_screen.dart';
import 'features/meditation_generator/meditation_generated_screen.dart';
import 'features/breathing/breathing_setup_screen.dart';
import 'features/routine/routine_screen.dart';
import 'features/history/history_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/player/meditation_player_screen.dart';
import 'services/ai_service.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'splash',
      pageBuilder: (context, state) => const MaterialPage<void>(
        child: SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) => const MaterialPage<void>(
        child: OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      pageBuilder: (context, state) => const MaterialPage<void>(
        child: HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/generator',
      name: 'generator',
      pageBuilder: (context, state) => const MaterialPage<void>(
        child: MeditationGeneratorScreen(),
      ),
    ),
    GoRoute(
      path: '/generator/result',
      name: 'generator_result',
      pageBuilder: (context, state) {
        final meditation = state.extra as GeneratedMeditation?;
        if (meditation != null) {
          return MaterialPage<void>(
            child: MeditationGeneratedScreen(meditation: meditation),
          );
        }
        return const MaterialPage<void>(
          child: Scaffold(
            body: Center(child: Text('No meditation data')),
          ),
        );
      },
    ),
    GoRoute(
      path: '/breathing',
      name: 'breathing',
      pageBuilder: (context, state) => const MaterialPage<void>(
        child: BreathingSetupScreen(),
      ),
    ),
    GoRoute(
      path: '/routine',
      name: 'routine',
      pageBuilder: (context, state) => const MaterialPage<void>(
        child: RoutineScreen(),
      ),
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      pageBuilder: (context, state) => const MaterialPage<void>(
        child: HistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/paywall',
      name: 'paywall',
      pageBuilder: (context, state) => const MaterialPage<void>(
        child: PaywallScreen(),
      ),
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      pageBuilder: (context, state) {
        final meditation = state.extra as GeneratedMeditation?;
        if (meditation != null) {
          return MaterialPage<void>(
            child: MeditationPlayerScreen(meditation: meditation),
          );
        }
        return const MaterialPage<void>(
          child: Scaffold(
            body: Center(child: Text('No meditation data')),
          ),
        );
      },
    ),
  ],
);

