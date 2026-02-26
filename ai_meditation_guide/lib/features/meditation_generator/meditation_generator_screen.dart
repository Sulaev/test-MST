import 'package:flutter/material.dart';

import 'meditation_generator_sheet.dart';

class MeditationGeneratorScreen extends StatefulWidget {
  const MeditationGeneratorScreen({super.key});

  @override
  State<MeditationGeneratorScreen> createState() => _MeditationGeneratorScreenState();
}

class _MeditationGeneratorScreenState extends State<MeditationGeneratorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await MeditationGeneratorSheet.show(context);
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Transparent placeholder page used only to launch the bottom sheet via route.
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}
