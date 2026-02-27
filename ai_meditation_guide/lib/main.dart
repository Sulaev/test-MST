import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'l10n/app_localizations.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool envLoaded = false;
  for (final path in ['assets/.env', '../.env', '.env']) {
    try {
      await dotenv.load(fileName: path);
      envLoaded = true;
      break;
    } catch (_) {}
  }
  if (!envLoaded) {
    try {
      await dotenv.load();
    } catch (_) {}
  }
  runApp(const ProviderScope(child: AiMeditationApp()));
}

class AiMeditationApp extends StatelessWidget {
  const AiMeditationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = appRouter;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB7C8FF)),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
