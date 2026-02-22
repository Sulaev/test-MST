# AI Meal Planner

Прототип утилиты для этапа B:
- Онлайн AI-режим генерации (бесплатный endpoint, без ключа)
- Локальный детерминированный fallback-режим
- Детерминированный кэш для AI-режима (одинаковый ввод => кэшированный ответ)
- Интеграция внешнего API рецептов (TheMealDB)
- Локальное хранение истории (SharedPreferences)
- Экспорт сгенерированных планов в PDF
- Пошаговый индикатор процесса генерации
- Обновленный мягкий интерфейс в стиле bubble + glass
- Локальная лента рецептов и GOAL-подсказки
- Подписки AppHud + атрибуция AppsFlyer/ATT
- Тестовая интеграция AdMob и инструменты Freepik (feature flags)
- План монетизации: docs/monetization_plan.md

## Запуск

```bash
flutter pub get
flutter run
```

## Безопасная конфигурация ключей (dart-define)

Ключи и идентификаторы **не храним в репозитории**. Передавайте их только через `--dart-define`.

Пример:

```bash
flutter run \
  --dart-define=FREEPIK_API_KEY=... \
  --dart-define=APPHUD_API_KEY=... \
  --dart-define=APPSFLYER_DEV_KEY=... \
  --dart-define=APPMETRICA_API_KEY=... \
  --dart-define=ADMOB_APP_ID=...
```

Поддерживаемые переменные:
- `FREEPIK_API_KEY`
- `APPHUD_API_KEY`, `APPHUD_PLACEMENT_ID`, `APPHUD_PAYWALL_ID`
- `APPHUD_PRODUCT_WEEKLY`, `APPHUD_PRODUCT_MONTHLY`
- `APPSFLYER_DEV_KEY`, `APPSFLYER_APPLE_APP_ID`
- `APPSFLYER_ATT_WAIT_SECONDS` (например `12`)
- `APPMETRICA_API_KEY`
- `ADMOB_APP_ID`, `ADMOB_BANNER_AD_UNIT_ID`, `ADMOB_INTERSTITIAL_AD_UNIT_ID`
- `ADMOB_REWARDED_AD_UNIT_ID`, `ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ID`
- `ADMOB_APP_OPEN_AD_UNIT_ID`, `ADMOB_NATIVE_AD_UNIT_ID`
- `ENABLE_ADS` (`true/false`)
- `ENABLE_FIREBASE_ANALYTICS` (`true/false`)
- `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID`, `FIREBASE_ANDROID_PROJECT_ID`
- `FIREBASE_ANDROID_SENDER_ID`, `FIREBASE_ANDROID_STORAGE_BUCKET`
- `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_PROJECT_ID`
- `FIREBASE_IOS_SENDER_ID`, `FIREBASE_IOS_BUNDLE_ID`, `FIREBASE_IOS_STORAGE_BUCKET`
- `ENABLE_FREEPIK_TOOLS` (`true/false`)
- `FREEPIK_BASE_URL` (по умолчанию `https://api.freepik.com`)

Firebase Analytics можно инициализировать двумя способами:
- Через `google-services.json` / `GoogleService-Info.plist` (добавьте локально и не коммитьте).
- Через `--dart-define` (переменные `FIREBASE_ANDROID_*` / `FIREBASE_IOS_*`).

Или из корня монорепозитория:

```bash
./run_simple.sh
```

## Запуск на iOS (требуется Mac)

Для тестирования на iOS нужен Mac с Xcode. Подробные инструкции:

- **Быстрый старт (5 минут):** [`docs/ios_quick_start.md`](docs/ios_quick_start.md)
- **Полная инструкция:** [`docs/ios_setup_mac.md`](docs/ios_setup_mac.md)

Кратко:
```bash
# На Mac:
cd /path/to/test-MST/ai-meal-planner
flutter pub get
cd ios && pod install && cd ..
open -a Simulator
cd /path/to/test-MST
./run_simple.sh ai-meal-planner -d "iPhone 15"
```

## Как пользоваться

1. Выберите цель, калории, количество дней, аллергии и предпочтения.
2. Выберите режим генерации:
   - **AI mode** (онлайн, retries + timeout, авто fallback)
   - **Fast mode** (полностью локальная детерминированная генерация)
3. Нажмите **Generate Meal Plan**.
4. Откройте ссылки на рецепты (если доступны), экспортируйте PDF и смотрите историю.
