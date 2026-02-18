import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/meal_plan.dart';
import 'services/ai_remote_meal_planner_service.dart';
import 'services/free_meal_planner_service.dart';
import 'services/plan_history_service.dart';
import 'services/pdf_export_service.dart';
import 'services/planner_generation_service.dart';
import 'services/recipe_lookup_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Meal Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MealPlannerHomePage(),
    );
  }
}

class MealPlannerHomePage extends StatefulWidget {
  const MealPlannerHomePage({super.key});

  @override
  State<MealPlannerHomePage> createState() => _MealPlannerHomePageState();
}

class _MealPlannerHomePageState extends State<MealPlannerHomePage> {
  static const List<String> _goals = <String>['weight_loss', 'muscle_gain', 'health'];

  final AiRemoteMealPlannerService _aiPlannerService = AiRemoteMealPlannerService();
  final FreeMealPlannerService _plannerService = FreeMealPlannerService();
  final RecipeLookupService _recipeService = RecipeLookupService();
  final PdfExportService _pdfExportService = PdfExportService();
  final PlanHistoryService _historyService = PlanHistoryService();
  late final PlannerGenerationService _generationService = PlannerGenerationService(
    aiService: _aiPlannerService,
    freeService: _plannerService,
    cacheStore: _historyService,
  );
  final TextEditingController _caloriesController = TextEditingController(text: '2100');
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _preferencesController = TextEditingController();

  PlannerMode _mode = PlannerMode.ai;
  String _selectedGoal = _goals.first;
  int _days = 3;
  bool _isGenerating = false;
  MealPlan? _currentPlan;
  List<MealPlan> _history = <MealPlan>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _allergiesController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final List<MealPlan> items = await _historyService.getHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = items;
    });
  }

  Future<void> _generate() async {
    final int? calories = int.tryParse(_caloriesController.text.trim());
    if (calories == null || calories < 900 || calories > 5000) {
      _showError('Daily calories must be a number between 900 and 5000.');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final PlannerGenerateResult generated = await _generationService.generate(
        mode: _mode,
        goal: _selectedGoal,
        dailyCalories: calories,
        days: _days,
        allergies: _allergiesController.text.trim(),
        preferences: _preferencesController.text.trim(),
      );
      if (generated.fromCache) {
        _showError('Loaded cached AI response for same parameters.');
      } else if (generated.usedFallback) {
        _showError('AI failed; used deterministic fallback.');
      }
      final MealPlan rawPlan = generated.plan;
      final MealPlan enrichedPlan = await _enrichWithRecipes(rawPlan);
      await _historyService.savePlan(enrichedPlan);
      final List<MealPlan> items = await _historyService.getHistory();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPlan = enrichedPlan;
        _history = items;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<MealPlan> _enrichWithRecipes(MealPlan plan) async {
    int lookupBudget = 10;
    final List<MealDay> days = <MealDay>[];
    for (final MealDay day in plan.days) {
      final List<MealEntry> meals = <MealEntry>[];
      for (final MealEntry meal in day.meals) {
        if (lookupBudget <= 0) {
          meals.add(meal);
          continue;
        }
        lookupBudget -= 1;
        try {
          final RecipeMatch? recipe = await _recipeService.findRecipe(meal.name);
          meals.add(
            meal.copyWith(
              recipeUrl: recipe?.sourceUrl,
              recipeImageUrl: recipe?.imageUrl,
            ),
          );
        } catch (_) {
          meals.add(meal);
        }
      }
      days.add(MealDay(day: day.day, meals: meals));
    }

    return MealPlan(
      createdAtIso: plan.createdAtIso,
      goal: plan.goal,
      dailyCalories: plan.dailyCalories,
      days: days,
      shoppingList: plan.shoppingList,
      tips: plan.tips,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openRecipe(String url) async {
    final Uri uri = Uri.parse(url);
    final bool opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showError('Could not open recipe URL.');
    }
  }

  Future<void> _clearHistory() async {
    await _historyService.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = <MealPlan>[];
    });
  }

  Future<void> _exportPlanPdf(MealPlan plan) async {
    try {
      final bytes = await _pdfExportService.buildPlanPdf(plan);
      final DateTime now = DateTime.now();
      final String filename =
          'meal_plan_${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError('PDF export failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Meal Planner'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Generate'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildGenerateTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: _selectedGoal,
          items: _goals
              .map((String goal) => DropdownMenuItem<String>(value: goal, child: Text(goal)))
              .toList(),
          onChanged: (String? value) {
            if (value == null) {
              return;
            }
            setState(() {
              _selectedGoal = value;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Goal',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<PlannerMode>(
          segments: const <ButtonSegment<PlannerMode>>[
            ButtonSegment<PlannerMode>(
              value: PlannerMode.ai,
              label: Text('AI mode'),
              icon: Icon(Icons.smart_toy_outlined),
            ),
            ButtonSegment<PlannerMode>(
              value: PlannerMode.deterministic,
              label: Text('Fast mode'),
              icon: Icon(Icons.bolt),
            ),
          ],
          selected: <PlannerMode>{_mode},
          onSelectionChanged: (Set<PlannerMode> selected) {
            setState(() {
              _mode = selected.first;
            });
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            _mode == PlannerMode.ai ? Icons.smart_toy_outlined : Icons.bolt,
            color: Colors.green,
          ),
          title: Text(
            _mode == PlannerMode.ai
                ? 'AI online mode (free endpoint)'
                : 'Deterministic local mode',
          ),
          subtitle: Text(
            _mode == PlannerMode.ai
                ? 'Retry + timeout handling enabled. On failure auto-fallback to local planner.'
                : 'No AI dependency. Fast and stable local generation.',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _caloriesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily Calories',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _allergiesController,
          decoration: const InputDecoration(
            labelText: 'Allergies',
            hintText: 'e.g. peanuts, lactose',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _preferencesController,
          decoration: const InputDecoration(
            labelText: 'Preferences',
            hintText: 'e.g. high-protein, quick meals',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text('Days: $_days'),
        Slider(
          value: _days.toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          label: '$_days',
          onChanged: (double value) {
            setState(() {
              _days = value.round();
            });
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : _generate,
          icon: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(_isGenerating ? 'Generating...' : 'Generate Meal Plan'),
        ),
        if (_currentPlan != null) ...<Widget>[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _exportPlanPdf(_currentPlan!),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export Current Plan to PDF'),
          ),
        ],
        const SizedBox(height: 20),
        if (_currentPlan != null) _buildPlanCard(_currentPlan!),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: <Widget>[
        if (_history.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _history.isEmpty
              ? const Center(child: Text('No saved meal plans yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _history.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MealPlan plan = _history[index];
                    final DateTime created = DateTime.tryParse(plan.createdAtIso) ?? DateTime.now();
                    return Card(
                      child: ExpansionTile(
                        title: Text(
                          '${plan.goal} - ${plan.dailyCalories} kcal',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${created.year}-${_two(created.month)}-${_two(created.day)} '
                          '${_two(created.hour)}:${_two(created.minute)}',
                        ),
                        children: <Widget>[
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                              child: TextButton.icon(
                                onPressed: () => _exportPlanPdf(plan),
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                                label: const Text('Export PDF'),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: _buildPlanDetails(plan),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(MealPlan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _buildPlanDetails(plan),
      ),
    );
  }

  Widget _buildPlanDetails(MealPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Goal: ${plan.goal} | ${plan.dailyCalories} kcal/day',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...plan.days.map(_buildDaySection),
        if (plan.shoppingList.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          const Text('Shopping list:', style: TextStyle(fontWeight: FontWeight.w700)),
          ...plan.shoppingList.map((String item) => Text('- $item')),
        ],
        if (plan.tips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          const Text('Tips:', style: TextStyle(fontWeight: FontWeight.w700)),
          ...plan.tips.map((String tip) => Text('- $tip')),
        ],
      ],
    );
  }

  Widget _buildDaySection(MealDay day) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(day.day, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ...day.meals.map(
            (MealEntry meal) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${meal.type}: ${meal.name}'),
              subtitle: Text('${meal.calories} kcal ${meal.notes.isEmpty ? "" : " | ${meal.notes}"}'),
              trailing: meal.recipeUrl == null
                  ? null
                  : IconButton(
                      tooltip: 'Open recipe',
                      onPressed: () => _openRecipe(meal.recipeUrl!),
                      icon: const Icon(Icons.open_in_new),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
