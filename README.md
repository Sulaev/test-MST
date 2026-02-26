# Flutter App Pack

В репозитории 8 Flutter-приложений:

- `ball-physics` - аркада с шариком и разрушаемыми кольцами.
- `aviation-game` - аркадный полет в стиле tappy-plane.
- `animals-encyclopedia` - энциклопедия животных с квизом.
- `education-subjects` - обучающее приложение (математика, физика, химия).
- `time-management` - задачи, таймер фокуса и планирование.
- `utility-app` - рабочий набор утилит (tasks/focus/notes/calc).
- `ai-meal-planner` - планировщик питания с AI-режимом, fallback-режимом, API рецептов и экспортом PDF.
- `ai-meditation-guide` - приложение для медитаций с AI‑генерацией сценариев, дыхательными практиками и ежедневной рутиной.

## Быстрый запуск

Из корня проекта:

```bash
./run_simple.sh
```

Скрипт покажет меню с выбором приложения по номеру `1..7`, затем:

1. выполнит `flutter pub get`;
2. покажет доступные устройства (`flutter devices`);
3. запустит приложение (`flutter run`).

## Запуск конкретного приложения

```bash
./run_simple.sh ball-physics
./run_simple.sh aviation-game
./run_simple.sh animals-encyclopedia
./run_simple.sh education-subjects
./run_simple.sh time-management
./run_simple.sh utility-app
./run_simple.sh ai-meal-planner
./run_simple.sh ai-meditation-guide
```

### Особенности `ai-meditation-guide`

- **Назначение**: генерация медитаций через GenAPI, дыхательные упражнения и «ежедневная рутина».
- **Запуск**: `./run_simple.sh ai-meditation-guide` (или через VS Code Task «Run ai-meditation-guide (run_simple.sh)`).
- **Секреты**: перед запуском создайте корневой `.env` с ключами:
  - `GENAPI_TOKEN` — токен для `https://gen-api.ru`;
  - `APPHUD_API_KEY` и продукты/пейволл для подписок;
  - при наличии — остальные ключи (AdMob, AppsFlyer, AppMetrica).
- Скрипт сам:
  - загружает `.env`;
  - пробрасывает значения в приложение через `--dart-define`;
  - копирует `.env` в `ai_meditation_guide/assets/.env`, чтобы приложение могло читать его через `flutter_dotenv` на симуляторе/устройстве.

## Как скрипт ищет Flutter

`run_simple.sh` поддерживает несколько сценариев:

- сначала пробует обычный `flutter` из PATH;
- в WSL, если `flutter` указывает на `/mnt/c/...`, переключается на Windows `flutter.bat`;
- если нужно, можно явно задать путь через переменную `FLUTTER_BAT_PATH`.

Пример:

```bash
FLUTTER_BAT_PATH='C:\src\flutter\bin\flutter.bat' ./run_simple.sh
```

## Требования

- Установленный Flutter (Linux/WSL или Windows).
- Запущенный эмулятор Android или подключенное устройство.
