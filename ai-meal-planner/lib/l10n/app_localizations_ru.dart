// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'AI Meal Planner';

  @override
  String get tabGenerate => 'Генерация';

  @override
  String get tabHistory => 'История';

  @override
  String get tabFeed => 'Лента';

  @override
  String get plannerInputs => 'Параметры плана';

  @override
  String get goal => 'Цель';

  @override
  String get aiMode => 'AI режим';

  @override
  String get fastMode => 'Быстрый режим';

  @override
  String get aiOnlineModeCurrent => 'AI онлайн режим (текущий endpoint)';

  @override
  String get deterministicLocalMode => 'Локальный детерминированный режим';

  @override
  String get aiModeDetails => 'Включены retry + timeout. При ошибке AI автоматически включается локальный fallback.';

  @override
  String get fastModeDetails => 'Без зависимости от AI. Быстрая и стабильная локальная генерация.';

  @override
  String get dailyCalories => 'Калории в день';

  @override
  String get allergies => 'Аллергии';

  @override
  String get allergiesHint => 'например: арахис, лактоза';

  @override
  String get preferences => 'Предпочтения';

  @override
  String get preferencesHint => 'например: high-protein, quick meals';

  @override
  String weeklyAdherenceLabel(int percent) {
    return 'Соблюдение плана за неделю: $percent%';
  }

  @override
  String daysLabel(int days) {
    return 'Дней: $days';
  }

  @override
  String get generating => 'Генерация...';

  @override
  String get generateMealPlan => 'Сгенерировать план питания';

  @override
  String get exportCurrentPlanPdf => 'Экспорт в PDF';

  @override
  String get refreshGoalTips => 'Обновить советы по цели';

  @override
  String get shareToLocalFeed => 'Опубликовать';

  @override
  String get generationStatus => 'Статус генерации';

  @override
  String get goalSupport => 'Поддержка цели';

  @override
  String secureConfigProvided(int count) {
    return 'Безопасная конфигурация: $count/15 ключей';
  }

  @override
  String get clear => 'Очистить';

  @override
  String get noSavedPlans => 'Сохраненных планов пока нет.';

  @override
  String get exportPdf => 'Экспорт PDF';

  @override
  String get feedEmpty => 'Лента пуста. Опубликуйте первый план.';

  @override
  String get favorite => 'Избранное';

  @override
  String get openRecipe => 'Открыть рецепт';

  @override
  String get shoppingList => 'Список покупок:';

  @override
  String get tips => 'Советы:';

  @override
  String goalKcalPerDay(Object goal, int kcal) {
    return 'Цель: $goal | $kcal ккал/день';
  }

  @override
  String get dailyCaloriesValidationError => 'Калории в день должны быть числом от 900 до 5000.';

  @override
  String get loadedCachedAiResponse => 'Загружен кэшированный AI-ответ для этих параметров.';

  @override
  String get aiFallbackUsed => 'AI недоступен, использован локальный fallback.';

  @override
  String get readyToGenerate => 'Готово к генерации.';

  @override
  String get checkingInput => 'Проверка входных параметров...';

  @override
  String get enrichingRecipes => 'Обогащаем блюда рецептами...';

  @override
  String get savingHistory => 'Сохранение плана в историю...';

  @override
  String get planReady => 'Ваш план готов.';

  @override
  String generationFailed(Object error) {
    return 'Ошибка генерации: $error';
  }

  @override
  String get postedToLocalFeed => 'Опубликовано в локальную ленту.';

  @override
  String get couldNotOpenRecipeUrl => 'Не удалось открыть ссылку на рецепт.';

  @override
  String pdfExportFailed(Object error) {
    return 'Ошибка экспорта PDF: $error';
  }

  @override
  String get waitingInput => 'Ожидание параметров';

  @override
  String get stepValidation => 'Шаг 1/6: Валидация';

  @override
  String get stepCache => 'Шаг 2/6: Проверка кэша';

  @override
  String get stepAiRequest => 'Шаг 3/6: Запрос к AI';

  @override
  String get stepLocalFallback => 'Шаг 4/6: Локальная генерация/fallback';

  @override
  String get stepEnrich => 'Шаг 5/6: Обогащение рецептами';

  @override
  String get stepSave => 'Шаг 6/6: Сохранение результата';

  @override
  String get done => 'Готово';

  @override
  String get failed => 'Ошибка';

  @override
  String get goalWeightLoss => 'Снижение веса';

  @override
  String get goalMuscleGain => 'Набор мышечной массы';

  @override
  String get goalHealth => 'Здоровье';

  @override
  String get goalMaintenanceRecomp => 'Поддержание / рекомпозиция';

  @override
  String get allFilter => 'Все';

  @override
  String get purchaseSuccess => 'Покупка завершена.';

  @override
  String get restoreSuccess => 'Покупки восстановлены.';

  @override
  String get subscriptionTitle => 'Подписка';

  @override
  String get subscriptionApiKeyMissing => 'APPHUD_API_KEY не задан. Передайте его через --dart-define для включения подписок.';

  @override
  String get subscriptionActive => 'Подписка активна';

  @override
  String get subscriptionInactive => 'Активной подписки нет';

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get subscriptionNoProducts => 'Для текущего placement/paywall продукты не найдены.';

  @override
  String get buy => 'Купить';

  @override
  String get trackingTitle => 'Трекинг и атрибуция';

  @override
  String get attStatus => 'Статус ATT';

  @override
  String get appsflyerStarted => 'AppsFlyer SDK запущен';

  @override
  String get appsflyerNotStarted => 'AppsFlyer SDK не запущен';

  @override
  String get appsflyerUid => 'AppsFlyer UID';

  @override
  String get conversionDataReceived => 'Данные конверсии получены';

  @override
  String get freepikToolsTitle => 'Инструменты Freepik';

  @override
  String get freepikImageUrl => 'Ссылка на изображение';

  @override
  String get freepikRemoveBackground => 'Удалить фон';

  @override
  String get freepikSegment => 'Сегментировать объект';

  @override
  String get freepikReady => 'Обработанное изображение готово';

  @override
  String get freepikEnterImageUrl => 'Сначала введите ссылку на изображение.';

  @override
  String get kcalUnit => 'ккал';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileGender => 'Пол';

  @override
  String get profileGenderMale => 'Мужской';

  @override
  String get profileGenderFemale => 'Женский';

  @override
  String get profileGenderOther => 'Другое';

  @override
  String get profileWeight => 'Вес';

  @override
  String get profileHeight => 'Рост';

  @override
  String get profileKg => 'кг';

  @override
  String get profileCm => 'см';

  @override
  String get profileGoal => 'Цель';

  @override
  String get profileLanguage => 'Язык';

  @override
  String get profileLanguageSystem => 'Системный';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageRussian => 'Русский';

  @override
  String get profileSave => 'Сохранить';

  @override
  String get profileCancel => 'Отмена';

  @override
  String get achievementsTitle => 'Достижения';

  @override
  String get achFirstPlanTitle => 'Первый рацион';

  @override
  String get achFirstPlanSubtitle => 'Создайте свой первый план питания.';

  @override
  String get ach3PlansTitle => 'Создано 3 плана';

  @override
  String get ach3PlansSubtitle => 'Сгенерируйте 3 плана питания.';

  @override
  String get ach5PlansTitle => 'Создано 5 планов';

  @override
  String get ach5PlansSubtitle => 'Сгенерируйте 5 планов питания.';

  @override
  String get ach7PlansTitle => 'Создано 7 планов';

  @override
  String get ach7PlansSubtitle => 'Сгенерируйте 7 планов питания.';

  @override
  String get achShareFeedTitle => 'Опубликовано в ленте';

  @override
  String get achShareFeedSubtitle => 'Поделитесь интересным планом в ленту.';

  @override
  String get achFavoriteTitle => 'Куратор ленты';

  @override
  String get achFavoriteSubtitle => 'Добавьте хотя бы один пост в избранное.';

  @override
  String get achCopyPlanTitle => 'Сохранено из ленты';

  @override
  String get achCopyPlanSubtitle => 'Скопируйте план из ленты в историю.';

  @override
  String get achExportPdfTitle => 'Экспорт в PDF';

  @override
  String get achExportPdfSubtitle => 'Экспортируйте план в PDF.';

  @override
  String get achOpenRecipeTitle => 'Открыл рецепт';

  @override
  String get achOpenRecipeSubtitle => 'Откройте ссылку на рецепт.';

  @override
  String get feedOpenPlan => 'Открыть план';

  @override
  String get feedCopyPlan => 'Копировать';

  @override
  String get feedCopiedToHistory => 'Скопировано в историю.';

  @override
  String get feedPlanUnavailable => 'В этом посте нет полного плана.';

  @override
  String get feedFollowPlan => 'Следовать';

  @override
  String get feedFollowingNow => 'План добавлен. Можно начинать следовать.';
}
