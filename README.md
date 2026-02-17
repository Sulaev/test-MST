# Flutter App Pack

В репозитории 6 Flutter-приложений:

- `ball-physics` - аркада с шариком и разрушаемыми кольцами.
- `aviation-game` - аркадный полет в стиле tappy-plane.
- `animals-encyclopedia` - энциклопедия животных с квизом.
- `education-subjects` - обучающее приложение (математика, физика, химия).
- `time-management` - задачи, таймер фокуса и планирование.
- `utility-app` - рабочий набор утилит (tasks/focus/notes/calc).

## Быстрый запуск

Из корня проекта:

```bash
./run_simple.sh
```

Скрипт покажет меню с выбором приложения по номеру `1..6`, затем:

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
```

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
