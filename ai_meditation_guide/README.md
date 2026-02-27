# ai_meditation_guide

Приложение‑проводник по медитациям:

- генерация сценариев медитаций через GenAPI;
- дыхательные практики;
- ежедневная рутина с отслеживанием прогресса;
- paywall c подпиской (Apphud).

## Запуск из корня репозитория

```bash
./run_simple.sh ai-meditation-guide
```

Скрипт:

- устанавливает зависимости (`flutter pub get`);
- проверяет доступные устройства;
- пробрасывает конфигурацию через `--dart-define`;
- копирует корневой `.env` в `ai_meditation_guide/assets/.env`, чтобы приложение могло читать его через `flutter_dotenv`.

## Конфигурация `.env`

Создайте файл `.env` в корне репозитория (он уже в `.gitignore`) и добавьте в него:

```bash
GENAPI_TOKEN=sk-...
APPHUD_API_KEY=app_...
APPHUD_PLACEMENT_ID=main_placement
APPHUD_PAYWALL_ID=main_paywall
APPHUD_PRODUCT_WEEKLY=sonicforge_weekly
APPHUD_PRODUCT_MONTHLY=sonicforge_monthly
```

При наличии можно также задать:

- `ADMOB_APP_ID` и ad unit IDs;
- `APPSFLYER_DEV_KEY`, `APPSFLYER_APPLE_APP_ID`, `APPSFLYER_ATT_WAIT_SECONDS`;
- `APPMETRICA_API_KEY`.

Эти значения автоматически попадают в приложение:

- через `--dart-define` (используются в коде через `String.fromEnvironment`);
- через `assets/.env` (используются в `AppConfig` как fallback через `flutter_dotenv`).
