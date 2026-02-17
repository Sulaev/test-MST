import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _rateController = TextEditingController(text: '25');
  final TextEditingController _hoursController = TextEditingController(text: '8');
  final TextEditingController _taxController = TextEditingController(text: '10');

  double _gross = 0;
  double _net = 0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _hoursController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  void _calculate() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final hours = double.tryParse(_hoursController.text) ?? 0;
    final tax = double.tryParse(_taxController.text) ?? 0;

    final gross = rate * hours;
    final net = gross * (1 - (tax.clamp(0, 100) / 100));

    setState(() {
      _gross = gross;
      _net = net;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Work Rate Calculator',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _rateController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hourly rate',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _calculate(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hoursController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hours worked',
            prefixIcon: Icon(Icons.schedule),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _calculate(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _taxController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tax (%)',
            prefixIcon: Icon(Icons.percent),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _calculate(),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gross: ${_gross.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text(
                  'Net: ${_net.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
