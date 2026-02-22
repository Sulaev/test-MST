import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pages/profile_page.dart';
import 'l10n/app_localizations.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'config/app_config.dart';
import 'models/generation_stage.dart';
import 'models/feed_post.dart';
import 'models/meal_plan.dart';
import 'services/ai_remote_meal_planner_service.dart';
import 'services/admob_service.dart';
import 'services/apphud_service.dart';
import 'services/appsflyer_service.dart';
import 'services/appmetrica_service.dart';
import 'services/att_service.dart';
import 'services/feed_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/free_meal_planner_service.dart';
import 'services/plan_history_service.dart';
import 'services/pdf_export_service.dart';
import 'services/planner_generation_service.dart';
import 'services/recipe_lookup_service.dart';

void main() {
  const bool enableExternalServices =
      bool.fromEnvironment('ENABLE_EXTERNAL_SERVICES', defaultValue: true);
  if (kDebugMode) {
    const String apphudKey = String.fromEnvironment('APPHUD_API_KEY', defaultValue: '');
    const String appsflyerKey = String.fromEnvironment('APPSFLYER_DEV_KEY', defaultValue: '');
    const String metricaKey = String.fromEnvironment('APPMETRICA_API_KEY', defaultValue: '');
    const String admobAppId = String.fromEnvironment('ADMOB_APP_ID', defaultValue: '');
    debugPrint(
      'dart-defines: '
      'ENABLE_EXTERNAL_SERVICES=$enableExternalServices, '
      'APPHUD_API_KEY=${apphudKey.isNotEmpty} len=${apphudKey.length}, '
      'APPSFLYER_DEV_KEY=${appsflyerKey.isNotEmpty} len=${appsflyerKey.length}, '
      'APPMETRICA_API_KEY=${metricaKey.isNotEmpty} len=${metricaKey.length}, '
      'ADMOB_APP_ID=${admobAppId.isNotEmpty} len=${admobAppId.length}',
    );
  }
  runApp(MyApp(enableExternalServices: enableExternalServices));
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.enableExternalServices = true,
  });

  final bool enableExternalServices;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void _setLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF62BFA8);
    const Color secondary = Color(0xFF95D9CC);
    const Color bg = Color(0xFFF2FAF7);
    return MaterialApp(
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          secondary: secondary,
        ),
        scaffoldBackgroundColor: bg,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white.withValues(alpha: 0.60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      home: MealPlannerHomePage(
        enableExternalServices: widget.enableExternalServices,
        onLocaleChanged: _setLocale,
        currentLocale: _locale,
      ),
    );
  }
}

class MealPlannerHomePage extends StatefulWidget {
  const MealPlannerHomePage({
    super.key,
    this.enableExternalServices = true,
    this.onLocaleChanged,
    this.currentLocale,
  });

  final bool enableExternalServices;
  final ValueChanged<Locale?>? onLocaleChanged;
  final Locale? currentLocale;

  @override
  State<MealPlannerHomePage> createState() => _MealPlannerHomePageState();
}

class _MealPlannerHomePageState extends State<MealPlannerHomePage> {
  static const List<String> _goals = <String>[
    'weight_loss',
    'muscle_gain',
    'health',
    'maintenance_recomp',
  ];

  final AiRemoteMealPlannerService _aiPlannerService = AiRemoteMealPlannerService();
  final FreeMealPlannerService _plannerService = FreeMealPlannerService();
  final RecipeLookupService _recipeService = RecipeLookupService();
  final PdfExportService _pdfExportService = PdfExportService();
  final PlanHistoryService _historyService = PlanHistoryService();
  final FeedService _feedService = FeedService();
  final ApphudService _apphudService = ApphudService();
  final AppsflyerService _appsflyerService = AppsflyerService();
  final AppMetricaService _appMetricaService = AppMetricaService();
  final AttService _attService = AttService();
  final AdmobService _admobService = AdmobService();
  final FirebaseAnalyticsService _firebaseAnalyticsService = FirebaseAnalyticsService();
  late final PlannerGenerationService _generationService = PlannerGenerationService(
    aiService: _aiPlannerService,
    freeService: _plannerService,
    cacheStore: _historyService,
  );
  final TextEditingController _caloriesController = TextEditingController(text: '2100');
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _preferencesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final AppConfig _appConfig = AppConfig.fromEnvironment();

  PlannerMode _mode = PlannerMode.ai;
  String _selectedGoal = _goals.first;
  int _days = 3;
  String _selectedGender = 'male';
  bool _isGenerating = false;
  GenerationProgress _progress = const GenerationProgress(
    stage: GenerationStage.idle,
    message: '',
    percent: 0,
  );
  final Set<String> _checkedMeals = <String>{};
  MealPlan? _currentPlan;
  List<MealPlan> _history = <MealPlan>[];
  List<String> _goalSupportTips = <String>[];
  List<FeedPost> _feedPosts = <FeedPost>[];
  String _feedFilterGoal = 'all';
  ApphudState _apphudState = const ApphudState.initial();
  late final VoidCallback _apphudListener;
  AppsflyerState _appsflyerState = const AppsflyerState.initial();
  late final VoidCallback _appsflyerListener;
  String _attStatus = 'notDetermined';
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _apphudListener = () {
      if (!mounted) {
        return;
      }
      setState(() {
        _apphudState = _apphudService.state.value;
      });
    };
    _apphudService.state.addListener(_apphudListener);
    _appsflyerListener = () {
      if (!mounted) {
        return;
      }
      setState(() {
        _appsflyerState = _appsflyerService.state.value;
      });
    };
    _appsflyerService.state.addListener(_appsflyerListener);
    _loadHistory();
    _loadFeed();
    if (widget.enableExternalServices) {
      // Important: initialize external SDKs sequentially.
      // AppsFlyer conversion callbacks may fire early and forward attribution to AppHud.
      // If AppHud is not started yet, native SDK can crash ("SDK not initialized").
      Future<void>.microtask(_initExternalServices);
    }
  }

  @override
  void dispose() {
    _apphudService.state.removeListener(_apphudListener);
    _apphudService.dispose();
    _appsflyerService.state.removeListener(_appsflyerListener);
    _appsflyerService.dispose();
    _appMetricaService.dispose();
    _admobService.dispose();
    _firebaseAnalyticsService.dispose();
    _caloriesController.dispose();
    _allergiesController.dispose();
    _preferencesController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _initAds() async {
    await _admobService.initialize(_appConfig);
    await _admobService.loadBanner(_appConfig);
    await _admobService.preloadInterstitial(_appConfig);
    await _admobService.preloadRewarded(_appConfig);
    await _admobService.preloadAppOpen(_appConfig);
  }

  Future<void> _initExternalServices() async {
    if (kDebugMode) {
      debugPrint('[ExternalServices] init sequence started');
    }
    try {
      await _initApphud().timeout(const Duration(seconds: 8));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ExternalServices] AppHud init failed/timed out: $error');
      }
    }
    if (kDebugMode) {
      debugPrint('[ExternalServices] AppHud init finished');
    }
    try {
      await _initTracking();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ExternalServices] Tracking init failed: $error');
      }
    }
    if (kDebugMode) {
      debugPrint('[ExternalServices] Tracking init finished');
    }
    try {
      await _initAds();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ExternalServices] Ads init failed: $error');
      }
    }
    if (kDebugMode) {
      debugPrint('[ExternalServices] Ads init finished');
    }
  }

  Future<void> _initApphud() async {
    await _apphudService.initialize(_appConfig);
    if (!mounted) {
      return;
    }
    setState(() {
      _apphudState = _apphudService.state.value;
    });
  }

  Future<void> _initTracking() async {
    String statusLabel = _attStatus;
    try {
      final TrackingStatus status = await _attService.requestIfNeeded();
      statusLabel = status.name;
      if (!mounted) {
        return;
      }
      setState(() {
        _attStatus = statusLabel;
      });
    } catch (_) {
      // ATT may be unavailable on non-iOS platforms.
    }

    await _appsflyerService.initialize(
      config: _appConfig,
      onConversionData: (Map<String, dynamic> conversionData, String? appsFlyerUid) async {
        await _apphudService.submitAppsFlyerAttribution(
          conversionData: conversionData,
          appsFlyerUid: appsFlyerUid,
        );
      },
    );
    await _appsflyerService.setAttStatus(statusLabel);
    await _apphudService.submitAppleSearchAdsAttribution();
    await _appMetricaService.initialize(_appConfig);
    await _firebaseAnalyticsService.initialize(_appConfig);
    await _apphudService.submitFirebaseAttribution(
      _firebaseAnalyticsService.buildAttributionData(),
    );
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

  Future<void> _loadFeed() async {
    final List<FeedPost> items = await _feedService.getPosts();
    if (!mounted) {
      return;
    }
    setState(() {
      _feedPosts = items;
    });
  }

  Future<void> _generate() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int? calories = int.tryParse(_caloriesController.text.trim());
    if (calories == null || calories < 900 || calories > 5000) {
      _showError(l10n.dailyCaloriesValidationError);
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = GenerationProgress(
        stage: GenerationStage.validatingInput,
        message: l10n.checkingInput,
        percent: 0.08,
      );
    });

    try {
      final PlannerGenerateResult generated = await _generationService.generate(
        mode: _mode,
        goal: _selectedGoal,
        dailyCalories: calories,
        days: _days,
        allergies: _allergiesController.text.trim(),
        preferences: _preferencesController.text.trim(),
        onProgress: (GenerationProgress progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            _progress = progress;
          });
        },
      );
      if (generated.fromCache) {
        _showError(l10n.loadedCachedAiResponse);
      } else if (generated.usedFallback) {
        _showError(l10n.aiFallbackUsed);
      }
      final MealPlan rawPlan = generated.plan;
      _setProgress(
        GenerationProgress(
          stage: GenerationStage.enrichingRecipes,
          message: l10n.enrichingRecipes,
          percent: 0.80,
        ),
      );
      final MealPlan enrichedPlan = await _enrichWithRecipes(rawPlan);
      _setProgress(
        GenerationProgress(
          stage: GenerationStage.savingHistory,
          message: l10n.savingHistory,
          percent: 0.93,
        ),
      );
      await _historyService.savePlan(enrichedPlan);
      final List<MealPlan> items = await _historyService.getHistory();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPlan = enrichedPlan;
        _history = items;
        _checkedMeals.clear();
        _progress = GenerationProgress(
          stage: GenerationStage.completed,
          message: l10n.planReady,
          percent: 1,
        );
      });
      await _appsflyerService.logEvent(
        'meal_plan_generated',
        <String, dynamic>{
          'goal': _selectedGoal,
          'days': _days,
          'mode': _mode.name,
        },
      );
      await _firebaseAnalyticsService.logEvent(
        'meal_plan_generated',
        <String, Object>{
          'goal': _selectedGoal,
          'days': _days,
          'mode': _mode.name,
        },
      );
      await _appMetricaService.logEvent(
        'meal_plan_generated',
        <String, dynamic>{
          'goal': _selectedGoal,
          'days': _days,
          'mode': _mode.name,
        },
      );
      await _admobService.showInterstitialIfAvailable(_appConfig);
      await _refreshGoalSupportTips();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setProgress(
        GenerationProgress(
          stage: GenerationStage.failed,
          message: l10n.generationFailed(error.toString()),
          percent: 1,
        ),
      );
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _refreshGoalSupportTips() async {
    try {
      final List<String> tips = await _aiPlannerService.generateGoalSupportTips(
        goal: _selectedGoal,
        preferences: _preferencesController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _goalSupportTips = tips;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _goalSupportTips = _localGoalSupportTips();
      });
    }
  }

  List<String> _localGoalSupportTips() {
    switch (_selectedGoal) {
      case 'weight_loss':
        return <String>[
          'Keep protein high in each meal to reduce hunger.',
          'Use one pre-planned snack to avoid random calories.',
          'Simplify meals on busy days to stay consistent.',
        ];
      case 'muscle_gain':
        return <String>[
          'Add 25-35 g of protein to breakfast and dinner.',
          'Place a calorie-dense snack around training.',
          'Prepare two repeatable meals for busy days.',
        ];
      case 'maintenance_recomp':
        return <String>[
          'Keep calories near target and prioritize strength training.',
          'Spread protein evenly across 4 meals.',
          'Track portions for the next 3 days to recalibrate.',
        ];
      case 'health':
        return <String>[
          'Target variety: different vegetables and protein sources daily.',
          'Hydrate consistently and reduce ultra-processed snacks.',
          'Start with one easy healthy swap each day.',
        ];
      default:
        return <String>[
          'Stay consistent with meal timing and hydration.',
          'Keep meals simple on busy days to stay on track.',
        ];
    }
  }

  Future<void> _publishCurrentPlanToFeed() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final MealPlan? plan = _currentPlan;
    if (plan == null) {
      return;
    }
    await _feedService.publishFromPlan(
      plan: plan,
      note: 'Generated in AI Meal Planner',
    );
    await _loadFeed();
    if (!mounted) {
      return;
    }
    _showError(l10n.postedToLocalFeed);
  }

  Future<void> _toggleFavoritePost(String id) async {
    await _feedService.toggleFavorite(id);
    await _loadFeed();
  }

  MealPlan? _planFromPost(FeedPost post) {
    final String? payload = post.planJson;
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }
    try {
      return MealPlan.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openPlanFromPost(FeedPost post) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final MealPlan? plan = _planFromPost(post);
    if (plan == null) {
      _showError(l10n.feedPlanUnavailable);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController scrollController) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SafeArea(
                top: false,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              post.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _followPlanFromPost(post);
                            },
                            child: Text(l10n.feedFollowPlan),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: <Widget>[
                          _buildPlanDetails(plan),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _followPlanFromPost(FeedPost post) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final MealPlan? plan = _planFromPost(post);
    if (plan == null) {
      _showError(l10n.feedPlanUnavailable);
      return;
    }
    final MealPlan copied = MealPlan(
      createdAtIso: DateTime.now().toIso8601String(),
      goal: plan.goal,
      dailyCalories: plan.dailyCalories,
      days: plan.days,
      shoppingList: plan.shoppingList,
      tips: plan.tips,
    );
    await _historyService.savePlan(copied);
    await _loadHistory();
    _followPlan(copied);
    _showError(l10n.feedFollowingNow);
  }

  void _followPlan(MealPlan plan) {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentPlan = plan;
      _selectedGoal = plan.goal;
      _caloriesController.text = plan.dailyCalories.toString();
      _checkedMeals.clear();
      _navIndex = 1; // Feed, Generate, History
    });
  }

  Future<void> _openHistoryPlan(MealPlan plan) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String title = '${_goalLabel(plan.goal, l10n)} • ${plan.dailyCalories} ${l10n.kcalUnit}';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController scrollController) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SafeArea(
                top: false,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _followPlan(plan);
                            },
                            child: Text(l10n.feedFollowPlan),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: <Widget>[
                          _buildPlanDetails(plan),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Future<void> _purchaseSubscription(ApphudProduct product) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? error = await _apphudService.purchase(product, _appConfig);
    if (!mounted) {
      return;
    }
    if (error != null && error.isNotEmpty) {
      _showError(error);
    } else {
      _showError(l10n.purchaseSuccess);
    }
  }

  Future<void> _restoreSubscriptions() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? error = await _apphudService.restore(_appConfig);
    if (!mounted) {
      return;
    }
    if (error != null && error.isNotEmpty) {
      _showError(error);
    } else {
      _showError(l10n.restoreSuccess);
    }
  }

  String _languageCodeFromLocale(Locale? locale) {
    if (locale == null) {
      return 'system';
    }
    return locale.languageCode;
  }

  Locale? _localeFromLanguageCode(String code) {
    switch (code) {
      case 'en':
        return const Locale('en');
      case 'ru':
        return const Locale('ru');
      default:
        return null;
    }
  }

  List<AchievementViewModel> _buildAchievements(AppLocalizations l10n) {
    final int planCount = _history.length;
    final int feedCount = _feedPosts.length;
    final int favoriteCount = _feedPosts.where((FeedPost p) => p.isFavorite).length;
    return <AchievementViewModel>[
      AchievementViewModel(
        title: l10n.achFirstPlanTitle,
        subtitle: l10n.achFirstPlanSubtitle,
        isUnlocked: planCount >= 1,
      ),
      AchievementViewModel(
        title: l10n.ach3PlansTitle,
        subtitle: l10n.ach3PlansSubtitle,
        isUnlocked: planCount >= 3,
      ),
      AchievementViewModel(
        title: l10n.ach5PlansTitle,
        subtitle: l10n.ach5PlansSubtitle,
        isUnlocked: planCount >= 5,
      ),
      AchievementViewModel(
        title: l10n.ach7PlansTitle,
        subtitle: l10n.ach7PlansSubtitle,
        isUnlocked: planCount >= 7,
      ),
      AchievementViewModel(
        title: l10n.achShareFeedTitle,
        subtitle: l10n.achShareFeedSubtitle,
        isUnlocked: feedCount >= 1,
      ),
      AchievementViewModel(
        title: l10n.achFavoriteTitle,
        subtitle: l10n.achFavoriteSubtitle,
        isUnlocked: favoriteCount >= 1,
      ),
      AchievementViewModel(
        title: l10n.achCopyPlanTitle,
        subtitle: l10n.achCopyPlanSubtitle,
        isUnlocked: planCount >= 2,
      ),
      AchievementViewModel(
        title: l10n.achExportPdfTitle,
        subtitle: l10n.achExportPdfSubtitle,
        isUnlocked: false,
      ),
      AchievementViewModel(
        title: l10n.achOpenRecipeTitle,
        subtitle: l10n.achOpenRecipeSubtitle,
        isUnlocked: false,
      ),
    ];
  }

  Future<void> _openProfilePage() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ProfileResult? result = await Navigator.of(context).push<ProfileResult>(
      MaterialPageRoute<ProfileResult>(
        builder: (BuildContext context) => ProfilePage(
          initialGender: _selectedGender,
          initialGoal: _selectedGoal,
          initialWeight: _weightController.text,
          initialHeight: _heightController.text,
          initialLanguageCode: _languageCodeFromLocale(widget.currentLocale),
          goalOptions: _goals,
          goalLabel: _goalLabel,
          apphudStateListenable: _apphudService.state,
          apphudHasConfig: _appConfig.apphudApiKey.trim().isNotEmpty,
          onPurchase: _purchaseSubscription,
          onRestore: _restoreSubscriptions,
          appsflyerStateListenable: _appsflyerService.state,
          attStatus: _attStatus,
          achievements: _buildAchievements(l10n),
          onRefreshExternalServices: () async {
            await _initExternalServices();
          },
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _selectedGender = result.gender;
      _selectedGoal = result.goal;
      _weightController.text = result.weight;
      _heightController.text = result.height;
    });
    widget.onLocaleChanged?.call(_localeFromLanguageCode(result.languageCode));
  }

  void _setProgress(GenerationProgress progress) {
    if (!mounted) {
      return;
    }
    setState(() {
      _progress = progress;
    });
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Uri uri = Uri.parse(url);
    final bool opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showError(l10n.couldNotOpenRecipeUrl);
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
      _showError(l10n.pdfExportFailed(error.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<Widget> pages = <Widget>[
      _buildFeedTab(),
      _buildGenerateTab(),
      _buildHistoryTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2AA845),
        foregroundColor: Colors.white,
        title: Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.profileTitle,
            onPressed: _openProfilePage,
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: _adaptivePage(pages[_navIndex]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        destinations: <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.dynamic_feed_outlined), label: l10n.tabFeed),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined), label: l10n.tabGenerate),
          NavigationDestination(icon: const Icon(Icons.insights_outlined), label: l10n.tabHistory),
        ],
        onDestinationSelected: (int index) {
          setState(() {
            _navIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildGenerateTab() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int goalCalories = int.tryParse(_caloriesController.text.trim()) ?? 2100;
    final MealDay? firstDay = _currentPlan?.days.firstOrNull;
    final int consumedCalories = firstDay == null
        ? 0
        : _checkedCalories(firstDay, 0);
    final int remainingCalories = goalCalories - consumedCalories;
    final double progress = goalCalories <= 0 ? 0 : (consumedCalories / goalCalories).clamp(0, 1);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2AA845),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(l10n.goal, style: const TextStyle(color: Colors.white70)),
                        Text(
                          '${_goalLabel(_selectedGoal, l10n)} • $goalCalories ${l10n.kcalUnit}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${remainingCalories >= 0 ? remainingCalories : 0} ${l10n.kcalUnit} left',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      SizedBox(
                        width: 84,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$consumedCalories',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(end: progress),
                builder: (BuildContext context, double animatedValue, Widget? child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: animatedValue,
                      minHeight: 14,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildGlass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SectionTitle(l10n.generateMealPlan),
              const SizedBox(height: 8),
              _GenerationProgressCard(
                progress: _progress,
                isGenerating: _isGenerating,
                l10n: l10n,
              ),
              const SizedBox(height: 8),
              _BubbleButton(
                onPressed: _isGenerating ? null : _generate,
                child: Text(_isGenerating ? l10n.generating : l10n.generateMealPlan),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.transparent)),
                  collapsedShape: const RoundedRectangleBorder(side: BorderSide(color: Colors.transparent)),
                  title: Text(l10n.plannerInputs, style: const TextStyle(fontWeight: FontWeight.w700)),
                  children: <Widget>[
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(_selectedGoal),
                    initialValue: _selectedGoal,
                    isExpanded: true,
                    items: _goals
                        .map((String goal) =>
                            DropdownMenuItem<String>(
                              value: goal,
                              child: Text(
                                _goalLabel(goal, l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedGoal = value;
                      });
                    },
                    decoration: InputDecoration(labelText: l10n.goal, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<PlannerMode>(
                    segments: <ButtonSegment<PlannerMode>>[
                      ButtonSegment<PlannerMode>(
                        value: PlannerMode.ai,
                        label: Text(l10n.aiMode),
                        icon: const Icon(Icons.smart_toy_outlined),
                      ),
                      ButtonSegment<PlannerMode>(
                        value: PlannerMode.deterministic,
                        label: Text(l10n.fastMode),
                        icon: const Icon(Icons.bolt),
                      ),
                    ],
                    selected: <PlannerMode>{_mode},
                    onSelectionChanged: (Set<PlannerMode> selected) {
                      setState(() {
                        _mode = selected.first;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(labelText: l10n.dailyCalories, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _allergiesController,
                    decoration: InputDecoration(
                      labelText: l10n.allergies,
                      hintText: l10n.allergiesHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _preferencesController,
                    decoration: InputDecoration(
                      labelText: l10n.preferences,
                      hintText: l10n.preferencesHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(l10n.daysLabel(_days)),
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
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(animation),
                child: child,
              ),
            );
          },
          child: firstDay == null
              ? const SizedBox.shrink(key: ValueKey<String>('no_plan'))
              : KeyedSubtree(
                  key: ValueKey<String>('plan_${_currentPlan?.createdAtIso ?? ""}'),
                  child: _buildGlass(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SectionTitle(firstDay.day),
                        const SizedBox(height: 6),
                        ...firstDay.meals.asMap().entries.map(
                          (MapEntry<int, MealEntry> entry) {
                            final int index = entry.key;
                            final MealEntry meal = entry.value;
                            final bool isChecked = _checkedMeals.contains(_mealKey(0, index));
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Checkbox(
                                value: isChecked,
                                activeColor: const Color(0xFF2AA845),
                                onChanged: (bool? value) => _toggleMealCheck(0, index, value),
                              ),
                              title: Text('${meal.type} • ${meal.name}'),
                              subtitle: Text('${meal.calories} kcal'),
                              trailing: meal.recipeUrl == null
                                  ? null
                                  : IconButton(
                                      tooltip: l10n.openRecipe,
                                      onPressed: () => _openRecipe(meal.recipeUrl!),
                                      icon: const Icon(Icons.open_in_new),
                                    ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _exportPlanPdf(_currentPlan!),
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                                label: Text(l10n.exportCurrentPlanPdf),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _publishCurrentPlanToFeed,
                                icon: const Icon(Icons.dynamic_feed_outlined),
                                label: Text(l10n.shareToLocalFeed),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (_goalSupportTips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _buildGlass(
            child: _GoalSupportCard(tips: _goalSupportTips, l10n: l10n),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryTab() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
                  label: Text(l10n.clear),
                ),
              ],
            ),
          ),
        Expanded(
          child: _history.isEmpty
              ? Center(child: Text(l10n.noSavedPlans))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _history.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MealPlan plan = _history[index];
                    final DateTime created = DateTime.tryParse(plan.createdAtIso) ?? DateTime.now();
                    return _buildGlass(
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.transparent)),
                          collapsedShape:
                              const RoundedRectangleBorder(side: BorderSide(color: Colors.transparent)),
                          title: Text(
                            '${plan.goal} - ${plan.dailyCalories} kcal',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${created.year}-${_two(created.month)}-${_two(created.day)} '
                            '${_two(created.hour)}:${_two(created.minute)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                tooltip: l10n.feedOpenPlan,
                                onPressed: () => _openHistoryPlan(plan),
                                icon: const Icon(Icons.receipt_long_outlined),
                              ),
                              FilledButton.tonal(
                                onPressed: () => _followPlan(plan),
                                child: Text(l10n.feedFollowPlan),
                              ),
                            ],
                          ),
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                                child: TextButton.icon(
                                  onPressed: () => _exportPlanPdf(plan),
                                  icon: const Icon(Icons.picture_as_pdf_outlined),
                                  label: Text(l10n.exportPdf),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: _buildPlanDetails(plan),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFeedTab() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<FeedPost> filtered = _feedFilterGoal == 'all'
        ? _feedPosts
        : _feedPosts.where((FeedPost post) => post.goal == _feedFilterGoal).toList();
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <String>['all', ..._goals].map((String goal) {
                final bool selected = _feedFilterGoal == goal;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(goal == 'all' ? l10n.allFilter : _goalLabel(goal, l10n)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _feedFilterGoal = goal;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(l10n.feedEmpty))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (BuildContext context, int index) {
                    final FeedPost post = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildGlass(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    post.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.favorite,
                                  onPressed: () => _toggleFavoritePost(post.id),
                                  icon: Icon(
                                    post.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: post.isFavorite ? Colors.pink : null,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${post.goal} • ${post.recipeName}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (post.note.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(post.note),
                            ],
                            if (post.recipeUrl != null && post.recipeUrl!.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => _openRecipe(post.recipeUrl!),
                                icon: const Icon(Icons.open_in_new),
                                label: Text(l10n.openRecipe),
                              ),
                            ],
                            if (post.planJson != null && post.planJson!.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  TextButton.icon(
                                    onPressed: () => _openPlanFromPost(post),
                                    icon: const Icon(Icons.receipt_long_outlined),
                                    label: Text(l10n.feedOpenPlan),
                                  ),
                                  const Spacer(),
                                  FilledButton.icon(
                                    onPressed: () => _followPlanFromPost(post),
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: Text(l10n.feedFollowPlan),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_appConfig.enableAds)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: _admobService.isBannerReady,
                builder: (BuildContext context, bool ready, Widget? child) {
                  if (!ready) {
                    return const SizedBox.shrink();
                  }
                  return _admobService.buildBannerWidget() ?? const SizedBox.shrink();
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanDetails(MealPlan plan) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.goalKcalPerDay(_goalLabel(plan.goal, l10n), plan.dailyCalories),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...plan.days.map(_buildDaySection),
        if (plan.shoppingList.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(l10n.shoppingList, style: const TextStyle(fontWeight: FontWeight.w700)),
          ...plan.shoppingList.map((String item) => Text('- $item')),
        ],
        if (plan.tips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(l10n.tips, style: const TextStyle(fontWeight: FontWeight.w700)),
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
                      tooltip: AppLocalizations.of(context)!.openRecipe,
                      onPressed: () => _openRecipe(meal.recipeUrl!),
                      icon: const Icon(Icons.open_in_new),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _mealKey(int dayIndex, int mealIndex) => '$dayIndex:$mealIndex';

  int _checkedCalories(MealDay day, int dayIndex) {
    int total = 0;
    for (int i = 0; i < day.meals.length; i += 1) {
      if (_checkedMeals.contains(_mealKey(dayIndex, i))) {
        total += day.meals[i].calories;
      }
    }
    return total;
  }

  void _toggleMealCheck(int dayIndex, int mealIndex, bool? value) {
    final bool shouldCheck = value ?? false;
    setState(() {
      final String key = _mealKey(dayIndex, mealIndex);
      if (shouldCheck) {
        _checkedMeals.add(key);
      } else {
        _checkedMeals.remove(key);
      }
    });
  }

  String _goalLabel(String goal, AppLocalizations l10n) {
    switch (goal) {
      case 'weight_loss':
        return l10n.goalWeightLoss;
      case 'muscle_gain':
        return l10n.goalMuscleGain;
      case 'maintenance_recomp':
        return l10n.goalMaintenanceRecomp;
      case 'health':
      default:
        return l10n.goalHealth;
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  Widget _adaptivePage(Widget child) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Orientation orientation = MediaQuery.of(context).orientation;
        final double screenWidth = constraints.maxWidth;
        
        // Адаптивные отступы в зависимости от размера экрана и ориентации
        double horizontal;
        if (orientation == Orientation.landscape) {
          // Ландшафтная ориентация: больше отступы для широких экранов
          horizontal = screenWidth >= 1200
              ? 24
              : screenWidth >= 900
                  ? 16
                  : screenWidth >= 700
                      ? 12
                      : 8;
        } else {
          // Портретная ориентация
          horizontal = screenWidth >= 1200
              ? 20
              : screenWidth >= 700
                  ? 12
                  : 0;
        }
        
        // Максимальная ширина контента для планшетов и десктопов
        final double maxContentWidth = screenWidth >= 1200 ? 1200 : double.infinity;
        
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlass({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E9E6)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GenerationProgressCard extends StatelessWidget {
  const _GenerationProgressCard({
    required this.progress,
    required this.isGenerating,
    required this.l10n,
  });

  final GenerationProgress progress;
  final bool isGenerating;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _colorFor(progress.stage);
    final double target = isGenerating ? progress.percent.clamp(0.02, 0.98) : progress.percent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.generationStatus,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7C76),
              ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Row(
            key: ValueKey<String>('${progress.stage.name}:${progress.message}'),
            children: <Widget>[
              Icon(_iconFor(progress.stage), color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.stage == GenerationStage.failed && progress.message.isNotEmpty
                      ? progress.message
                      : _defaultMessageFor(progress.stage),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(end: target),
          builder: (BuildContext context, double value, Widget? child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: const Color(0xFFE4F4F0),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            key: ValueKey<String>(progress.stage.name),
            _labelFor(progress.stage),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  String _defaultMessageFor(GenerationStage stage) {
    switch (stage) {
      case GenerationStage.idle:
        return l10n.readyToGenerate;
      case GenerationStage.validatingInput:
        return l10n.checkingInput;
      case GenerationStage.checkingCache:
        return l10n.stepCache;
      case GenerationStage.requestingAi:
        return l10n.stepAiRequest;
      case GenerationStage.generatingLocal:
        return l10n.stepLocalFallback;
      case GenerationStage.enrichingRecipes:
        return l10n.enrichingRecipes;
      case GenerationStage.savingHistory:
        return l10n.savingHistory;
      case GenerationStage.completed:
        return l10n.planReady;
      case GenerationStage.failed:
        return l10n.failed;
    }
  }

  String _labelFor(GenerationStage stage) {
    switch (stage) {
      case GenerationStage.idle:
        return l10n.waitingInput;
      case GenerationStage.validatingInput:
        return l10n.stepValidation;
      case GenerationStage.checkingCache:
        return l10n.stepCache;
      case GenerationStage.requestingAi:
        return l10n.stepAiRequest;
      case GenerationStage.generatingLocal:
        return l10n.stepLocalFallback;
      case GenerationStage.enrichingRecipes:
        return l10n.stepEnrich;
      case GenerationStage.savingHistory:
        return l10n.stepSave;
      case GenerationStage.completed:
        return l10n.done;
      case GenerationStage.failed:
        return l10n.failed;
    }
  }

  IconData _iconFor(GenerationStage stage) {
    switch (stage) {
      case GenerationStage.idle:
        return Icons.hourglass_bottom;
      case GenerationStage.validatingInput:
        return Icons.rule;
      case GenerationStage.checkingCache:
        return Icons.memory;
      case GenerationStage.requestingAi:
        return Icons.auto_awesome;
      case GenerationStage.generatingLocal:
        return Icons.bolt;
      case GenerationStage.enrichingRecipes:
        return Icons.restaurant_menu_outlined;
      case GenerationStage.savingHistory:
        return Icons.save_alt;
      case GenerationStage.completed:
        return Icons.check_circle_outline;
      case GenerationStage.failed:
        return Icons.error_outline;
    }
  }

  Color _colorFor(GenerationStage stage) {
    switch (stage) {
      case GenerationStage.failed:
        return const Color(0xFFC24D5A);
      case GenerationStage.completed:
        return const Color(0xFF2E9C74);
      default:
        return const Color(0xFF2D7E8A);
    }
  }
}

class _GoalSupportCard extends StatelessWidget {
  const _GoalSupportCard({
    required this.tips,
    required this.l10n,
  });

  final List<String> tips;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(l10n.goalSupport),
        const SizedBox(height: 8),
        ...tips.map(
          (String tip) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.bubble_chart_outlined, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(tip)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _BubbleButton extends StatelessWidget {
  const _BubbleButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        backgroundColor: const Color(0xFF66C3AD),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      child: child,
    );
  }
}
