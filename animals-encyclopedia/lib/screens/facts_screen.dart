import 'package:flutter/material.dart';

class FactsScreen extends StatelessWidget {
  const FactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const facts = <String>[
      'Dolphins can recognize themselves in mirrors.',
      'Owls can rotate their heads up to 270 degrees.',
      'Elephants use low-frequency sounds to communicate over long distances.',
      'Penguins can drink sea water thanks to a special gland.',
      'Tigers have unique stripe patterns, like human fingerprints.',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Facts')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: facts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.bolt_rounded),
              title: Text('Fact ${index + 1}'),
              subtitle: Text(facts[index]),
            ),
          );
        },
      ),
    );
  }
}
