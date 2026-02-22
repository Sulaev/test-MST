import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Meal Planner'**
  String get appTitle;

  /// No description provided for @tabGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get tabGenerate;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get tabFeed;

  /// No description provided for @plannerInputs.
  ///
  /// In en, this message translates to:
  /// **'Planner Inputs'**
  String get plannerInputs;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @aiMode.
  ///
  /// In en, this message translates to:
  /// **'AI mode'**
  String get aiMode;

  /// No description provided for @fastMode.
  ///
  /// In en, this message translates to:
  /// **'Fast mode'**
  String get fastMode;

  /// No description provided for @aiOnlineModeCurrent.
  ///
  /// In en, this message translates to:
  /// **'AI online mode (current endpoint)'**
  String get aiOnlineModeCurrent;

  /// No description provided for @deterministicLocalMode.
  ///
  /// In en, this message translates to:
  /// **'Deterministic local mode'**
  String get deterministicLocalMode;

  /// No description provided for @aiModeDetails.
  ///
  /// In en, this message translates to:
  /// **'Retry + timeout handling enabled. On failure auto-fallback to local planner.'**
  String get aiModeDetails;

  /// No description provided for @fastModeDetails.
  ///
  /// In en, this message translates to:
  /// **'No AI dependency. Fast and stable local generation.'**
  String get fastModeDetails;

  /// No description provided for @dailyCalories.
  ///
  /// In en, this message translates to:
  /// **'Daily Calories'**
  String get dailyCalories;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @allergiesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. peanuts, lactose'**
  String get allergiesHint;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @preferencesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. high-protein, quick meals'**
  String get preferencesHint;

  /// No description provided for @weeklyAdherenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly plan adherence: {percent}%'**
  String weeklyAdherenceLabel(int percent);

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days: {days}'**
  String daysLabel(int days);

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @generateMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Generate Meal Plan'**
  String get generateMealPlan;

  /// No description provided for @exportCurrentPlanPdf.
  ///
  /// In en, this message translates to:
  /// **'Export Current Plan to PDF'**
  String get exportCurrentPlanPdf;

  /// No description provided for @refreshGoalTips.
  ///
  /// In en, this message translates to:
  /// **'Refresh Goal Support Tips'**
  String get refreshGoalTips;

  /// No description provided for @shareToLocalFeed.
  ///
  /// In en, this message translates to:
  /// **'Share to Local Feed'**
  String get shareToLocalFeed;

  /// No description provided for @generationStatus.
  ///
  /// In en, this message translates to:
  /// **'Generation Status'**
  String get generationStatus;

  /// No description provided for @goalSupport.
  ///
  /// In en, this message translates to:
  /// **'Goal Support'**
  String get goalSupport;

  /// No description provided for @secureConfigProvided.
  ///
  /// In en, this message translates to:
  /// **'Secure config provided: {count}/15 keys'**
  String secureConfigProvided(int count);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @noSavedPlans.
  ///
  /// In en, this message translates to:
  /// **'No saved meal plans yet.'**
  String get noSavedPlans;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Feed is empty. Share your first meal plan.'**
  String get feedEmpty;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @openRecipe.
  ///
  /// In en, this message translates to:
  /// **'Open recipe'**
  String get openRecipe;

  /// No description provided for @shoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping list:'**
  String get shoppingList;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips:'**
  String get tips;

  /// No description provided for @goalKcalPerDay.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} | {kcal} kcal/day'**
  String goalKcalPerDay(Object goal, int kcal);

  /// No description provided for @dailyCaloriesValidationError.
  ///
  /// In en, this message translates to:
  /// **'Daily calories must be a number between 900 and 5000.'**
  String get dailyCaloriesValidationError;

  /// No description provided for @loadedCachedAiResponse.
  ///
  /// In en, this message translates to:
  /// **'Loaded cached AI response for same parameters.'**
  String get loadedCachedAiResponse;

  /// No description provided for @aiFallbackUsed.
  ///
  /// In en, this message translates to:
  /// **'AI failed; used deterministic fallback.'**
  String get aiFallbackUsed;

  /// No description provided for @readyToGenerate.
  ///
  /// In en, this message translates to:
  /// **'Ready to generate.'**
  String get readyToGenerate;

  /// No description provided for @checkingInput.
  ///
  /// In en, this message translates to:
  /// **'Checking input parameters...'**
  String get checkingInput;

  /// No description provided for @enrichingRecipes.
  ///
  /// In en, this message translates to:
  /// **'Enriching meals with recipes...'**
  String get enrichingRecipes;

  /// No description provided for @savingHistory.
  ///
  /// In en, this message translates to:
  /// **'Saving plan to history...'**
  String get savingHistory;

  /// No description provided for @planReady.
  ///
  /// In en, this message translates to:
  /// **'Your plan is ready.'**
  String get planReady;

  /// No description provided for @generationFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed: {error}'**
  String generationFailed(Object error);

  /// No description provided for @postedToLocalFeed.
  ///
  /// In en, this message translates to:
  /// **'Posted to local feed.'**
  String get postedToLocalFeed;

  /// No description provided for @couldNotOpenRecipeUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open recipe URL.'**
  String get couldNotOpenRecipeUrl;

  /// No description provided for @pdfExportFailed.
  ///
  /// In en, this message translates to:
  /// **'PDF export failed: {error}'**
  String pdfExportFailed(Object error);

  /// No description provided for @waitingInput.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your input'**
  String get waitingInput;

  /// No description provided for @stepValidation.
  ///
  /// In en, this message translates to:
  /// **'Step 1/6: Validation'**
  String get stepValidation;

  /// No description provided for @stepCache.
  ///
  /// In en, this message translates to:
  /// **'Step 2/6: Cache check'**
  String get stepCache;

  /// No description provided for @stepAiRequest.
  ///
  /// In en, this message translates to:
  /// **'Step 3/6: AI request'**
  String get stepAiRequest;

  /// No description provided for @stepLocalFallback.
  ///
  /// In en, this message translates to:
  /// **'Step 4/6: Local generation/fallback'**
  String get stepLocalFallback;

  /// No description provided for @stepEnrich.
  ///
  /// In en, this message translates to:
  /// **'Step 5/6: Recipe enrichment'**
  String get stepEnrich;

  /// No description provided for @stepSave.
  ///
  /// In en, this message translates to:
  /// **'Step 6/6: Save result'**
  String get stepSave;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @goalWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight loss'**
  String get goalWeightLoss;

  /// No description provided for @goalMuscleGain.
  ///
  /// In en, this message translates to:
  /// **'Muscle gain'**
  String get goalMuscleGain;

  /// No description provided for @goalHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get goalHealth;

  /// No description provided for @goalMaintenanceRecomp.
  ///
  /// In en, this message translates to:
  /// **'Maintenance / Recomp'**
  String get goalMaintenanceRecomp;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase completed.'**
  String get purchaseSuccess;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get restoreSuccess;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionApiKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'APPHUD_API_KEY is not set. Add it via --dart-define to enable subscriptions.'**
  String get subscriptionApiKeyMissing;

  /// No description provided for @subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription active'**
  String get subscriptionActive;

  /// No description provided for @subscriptionInactive.
  ///
  /// In en, this message translates to:
  /// **'No active subscription'**
  String get subscriptionInactive;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @subscriptionNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products found for current placement/paywall.'**
  String get subscriptionNoProducts;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @trackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracking & Attribution'**
  String get trackingTitle;

  /// No description provided for @attStatus.
  ///
  /// In en, this message translates to:
  /// **'ATT status'**
  String get attStatus;

  /// No description provided for @appsflyerStarted.
  ///
  /// In en, this message translates to:
  /// **'AppsFlyer SDK started'**
  String get appsflyerStarted;

  /// No description provided for @appsflyerNotStarted.
  ///
  /// In en, this message translates to:
  /// **'AppsFlyer SDK not started'**
  String get appsflyerNotStarted;

  /// No description provided for @appsflyerUid.
  ///
  /// In en, this message translates to:
  /// **'AppsFlyer UID'**
  String get appsflyerUid;

  /// No description provided for @conversionDataReceived.
  ///
  /// In en, this message translates to:
  /// **'Conversion data received'**
  String get conversionDataReceived;

  /// No description provided for @freepikToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Freepik Image Tools'**
  String get freepikToolsTitle;

  /// No description provided for @freepikImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get freepikImageUrl;

  /// No description provided for @freepikRemoveBackground.
  ///
  /// In en, this message translates to:
  /// **'Remove background'**
  String get freepikRemoveBackground;

  /// No description provided for @freepikSegment.
  ///
  /// In en, this message translates to:
  /// **'Segment object'**
  String get freepikSegment;

  /// No description provided for @freepikReady.
  ///
  /// In en, this message translates to:
  /// **'Processed image is ready'**
  String get freepikReady;

  /// No description provided for @freepikEnterImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter an image URL first.'**
  String get freepikEnterImageUrl;

  /// No description provided for @kcalUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcalUnit;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileGenderMale;

  /// No description provided for @profileGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileGenderFemale;

  /// No description provided for @profileGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileGenderOther;

  /// No description provided for @profileWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get profileWeight;

  /// No description provided for @profileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeight;

  /// No description provided for @profileKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get profileKg;

  /// No description provided for @profileCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get profileCm;

  /// No description provided for @profileGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get profileGoal;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get profileLanguageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @achFirstPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'First meal plan'**
  String get achFirstPlanTitle;

  /// No description provided for @achFirstPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first plan.'**
  String get achFirstPlanSubtitle;

  /// No description provided for @ach3PlansTitle.
  ///
  /// In en, this message translates to:
  /// **'3 plans created'**
  String get ach3PlansTitle;

  /// No description provided for @ach3PlansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate 3 meal plans.'**
  String get ach3PlansSubtitle;

  /// No description provided for @ach5PlansTitle.
  ///
  /// In en, this message translates to:
  /// **'5 plans created'**
  String get ach5PlansTitle;

  /// No description provided for @ach5PlansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate 5 meal plans.'**
  String get ach5PlansSubtitle;

  /// No description provided for @ach7PlansTitle.
  ///
  /// In en, this message translates to:
  /// **'7 plans created'**
  String get ach7PlansTitle;

  /// No description provided for @ach7PlansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate 7 meal plans.'**
  String get ach7PlansSubtitle;

  /// No description provided for @achShareFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared to feed'**
  String get achShareFeedTitle;

  /// No description provided for @achShareFeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post an interesting plan to the feed.'**
  String get achShareFeedSubtitle;

  /// No description provided for @achFavoriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite curator'**
  String get achFavoriteTitle;

  /// No description provided for @achFavoriteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark at least one feed post as favorite.'**
  String get achFavoriteSubtitle;

  /// No description provided for @achCopyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved from feed'**
  String get achCopyPlanTitle;

  /// No description provided for @achCopyPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy a plan from the feed to your history.'**
  String get achCopyPlanSubtitle;

  /// No description provided for @achExportPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF exporter'**
  String get achExportPdfTitle;

  /// No description provided for @achExportPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export a plan to PDF.'**
  String get achExportPdfSubtitle;

  /// No description provided for @achOpenRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe explorer'**
  String get achOpenRecipeTitle;

  /// No description provided for @achOpenRecipeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a recipe link.'**
  String get achOpenRecipeSubtitle;

  /// No description provided for @feedOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'Open plan'**
  String get feedOpenPlan;

  /// No description provided for @feedCopyPlan.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get feedCopyPlan;

  /// No description provided for @feedCopiedToHistory.
  ///
  /// In en, this message translates to:
  /// **'Copied to your history.'**
  String get feedCopiedToHistory;

  /// No description provided for @feedPlanUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This post does not contain a full plan.'**
  String get feedPlanUnavailable;

  /// No description provided for @feedFollowPlan.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get feedFollowPlan;

  /// No description provided for @feedFollowingNow.
  ///
  /// In en, this message translates to:
  /// **'Plan added. You can follow it now.'**
  String get feedFollowingNow;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
