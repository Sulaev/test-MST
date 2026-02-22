// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Meal Planner';

  @override
  String get tabGenerate => 'Generate';

  @override
  String get tabHistory => 'History';

  @override
  String get tabFeed => 'Feed';

  @override
  String get plannerInputs => 'Planner Inputs';

  @override
  String get goal => 'Goal';

  @override
  String get aiMode => 'AI mode';

  @override
  String get fastMode => 'Fast mode';

  @override
  String get aiOnlineModeCurrent => 'AI online mode (current endpoint)';

  @override
  String get deterministicLocalMode => 'Deterministic local mode';

  @override
  String get aiModeDetails => 'Retry + timeout handling enabled. On failure auto-fallback to local planner.';

  @override
  String get fastModeDetails => 'No AI dependency. Fast and stable local generation.';

  @override
  String get dailyCalories => 'Daily Calories';

  @override
  String get allergies => 'Allergies';

  @override
  String get allergiesHint => 'e.g. peanuts, lactose';

  @override
  String get preferences => 'Preferences';

  @override
  String get preferencesHint => 'e.g. high-protein, quick meals';

  @override
  String weeklyAdherenceLabel(int percent) {
    return 'Weekly plan adherence: $percent%';
  }

  @override
  String daysLabel(int days) {
    return 'Days: $days';
  }

  @override
  String get generating => 'Generating...';

  @override
  String get generateMealPlan => 'Generate Meal Plan';

  @override
  String get exportCurrentPlanPdf => 'Export Current Plan to PDF';

  @override
  String get refreshGoalTips => 'Refresh Goal Support Tips';

  @override
  String get shareToLocalFeed => 'Share to Local Feed';

  @override
  String get generationStatus => 'Generation Status';

  @override
  String get goalSupport => 'Goal Support';

  @override
  String secureConfigProvided(int count) {
    return 'Secure config provided: $count/15 keys';
  }

  @override
  String get clear => 'Clear';

  @override
  String get noSavedPlans => 'No saved meal plans yet.';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get feedEmpty => 'Feed is empty. Share your first meal plan.';

  @override
  String get favorite => 'Favorite';

  @override
  String get openRecipe => 'Open recipe';

  @override
  String get shoppingList => 'Shopping list:';

  @override
  String get tips => 'Tips:';

  @override
  String goalKcalPerDay(Object goal, int kcal) {
    return 'Goal: $goal | $kcal kcal/day';
  }

  @override
  String get dailyCaloriesValidationError => 'Daily calories must be a number between 900 and 5000.';

  @override
  String get loadedCachedAiResponse => 'Loaded cached AI response for same parameters.';

  @override
  String get aiFallbackUsed => 'AI failed; used deterministic fallback.';

  @override
  String get readyToGenerate => 'Ready to generate.';

  @override
  String get checkingInput => 'Checking input parameters...';

  @override
  String get enrichingRecipes => 'Enriching meals with recipes...';

  @override
  String get savingHistory => 'Saving plan to history...';

  @override
  String get planReady => 'Your plan is ready.';

  @override
  String generationFailed(Object error) {
    return 'Generation failed: $error';
  }

  @override
  String get postedToLocalFeed => 'Posted to local feed.';

  @override
  String get couldNotOpenRecipeUrl => 'Could not open recipe URL.';

  @override
  String pdfExportFailed(Object error) {
    return 'PDF export failed: $error';
  }

  @override
  String get waitingInput => 'Waiting for your input';

  @override
  String get stepValidation => 'Step 1/6: Validation';

  @override
  String get stepCache => 'Step 2/6: Cache check';

  @override
  String get stepAiRequest => 'Step 3/6: AI request';

  @override
  String get stepLocalFallback => 'Step 4/6: Local generation/fallback';

  @override
  String get stepEnrich => 'Step 5/6: Recipe enrichment';

  @override
  String get stepSave => 'Step 6/6: Save result';

  @override
  String get done => 'Done';

  @override
  String get failed => 'Failed';

  @override
  String get goalWeightLoss => 'Weight loss';

  @override
  String get goalMuscleGain => 'Muscle gain';

  @override
  String get goalHealth => 'Health';

  @override
  String get goalMaintenanceRecomp => 'Maintenance / Recomp';

  @override
  String get allFilter => 'All';

  @override
  String get purchaseSuccess => 'Purchase completed.';

  @override
  String get restoreSuccess => 'Purchases restored.';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get subscriptionApiKeyMissing => 'APPHUD_API_KEY is not set. Add it via --dart-define to enable subscriptions.';

  @override
  String get subscriptionActive => 'Subscription active';

  @override
  String get subscriptionInactive => 'No active subscription';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get subscriptionNoProducts => 'No products found for current placement/paywall.';

  @override
  String get buy => 'Buy';

  @override
  String get trackingTitle => 'Tracking & Attribution';

  @override
  String get attStatus => 'ATT status';

  @override
  String get appsflyerStarted => 'AppsFlyer SDK started';

  @override
  String get appsflyerNotStarted => 'AppsFlyer SDK not started';

  @override
  String get appsflyerUid => 'AppsFlyer UID';

  @override
  String get conversionDataReceived => 'Conversion data received';

  @override
  String get freepikToolsTitle => 'Freepik Image Tools';

  @override
  String get freepikImageUrl => 'Image URL';

  @override
  String get freepikRemoveBackground => 'Remove background';

  @override
  String get freepikSegment => 'Segment object';

  @override
  String get freepikReady => 'Processed image is ready';

  @override
  String get freepikEnterImageUrl => 'Enter an image URL first.';

  @override
  String get kcalUnit => 'kcal';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileGenderMale => 'Male';

  @override
  String get profileGenderFemale => 'Female';

  @override
  String get profileGenderOther => 'Other';

  @override
  String get profileWeight => 'Weight';

  @override
  String get profileHeight => 'Height';

  @override
  String get profileKg => 'kg';

  @override
  String get profileCm => 'cm';

  @override
  String get profileGoal => 'Goal';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Russian';

  @override
  String get profileSave => 'Save';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achFirstPlanTitle => 'First meal plan';

  @override
  String get achFirstPlanSubtitle => 'Create your first plan.';

  @override
  String get ach3PlansTitle => '3 plans created';

  @override
  String get ach3PlansSubtitle => 'Generate 3 meal plans.';

  @override
  String get ach5PlansTitle => '5 plans created';

  @override
  String get ach5PlansSubtitle => 'Generate 5 meal plans.';

  @override
  String get ach7PlansTitle => '7 plans created';

  @override
  String get ach7PlansSubtitle => 'Generate 7 meal plans.';

  @override
  String get achShareFeedTitle => 'Shared to feed';

  @override
  String get achShareFeedSubtitle => 'Post an interesting plan to the feed.';

  @override
  String get achFavoriteTitle => 'Favorite curator';

  @override
  String get achFavoriteSubtitle => 'Mark at least one feed post as favorite.';

  @override
  String get achCopyPlanTitle => 'Saved from feed';

  @override
  String get achCopyPlanSubtitle => 'Copy a plan from the feed to your history.';

  @override
  String get achExportPdfTitle => 'PDF exporter';

  @override
  String get achExportPdfSubtitle => 'Export a plan to PDF.';

  @override
  String get achOpenRecipeTitle => 'Recipe explorer';

  @override
  String get achOpenRecipeSubtitle => 'Open a recipe link.';

  @override
  String get feedOpenPlan => 'Open plan';

  @override
  String get feedCopyPlan => 'Copy';

  @override
  String get feedCopiedToHistory => 'Copied to your history.';

  @override
  String get feedPlanUnavailable => 'This post does not contain a full plan.';

  @override
  String get feedFollowPlan => 'Follow';

  @override
  String get feedFollowingNow => 'Plan added. You can follow it now.';
}
