import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/meal_plan.dart';

class PdfExportService {
  Future<Uint8List> buildPlanPdf(MealPlan plan) async {
    final pw.Document doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => <pw.Widget>[
          pw.Header(
            level: 0,
            child: pw.Text(
              'AI Meal Planner',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Goal: ${plan.goal}'),
          pw.Text('Calories per day: ${plan.dailyCalories}'),
          pw.SizedBox(height: 12),
          ...plan.days.map(_buildDayBlock),
          if (plan.shoppingList.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 12),
            pw.Text('Shopping List', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...plan.shoppingList.map((String item) => pw.Bullet(text: item)),
          ],
          if (plan.tips.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 12),
            pw.Text('Tips', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...plan.tips.map((String tip) => pw.Bullet(text: tip)),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildDayBlock(MealDay day) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(day.day, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          ...day.meals.map(
            (MealEntry meal) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                '${meal.type}: ${meal.name} (${meal.calories} kcal)'
                '${meal.notes.isEmpty ? "" : " - ${meal.notes}"}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
