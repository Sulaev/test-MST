# 🚀 Быстрый старт iOS на Mac (5 минут)

## 1. Установка (один раз)

```bash
# Установите Xcode из App Store (бесплатно, ~12GB, 10-15 мин)
# После установки:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Установите Flutter через Homebrew:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install --cask flutter

# Установите CocoaPods:
sudo gem install cocoapods
```

## 2. Проверка

```bash
flutter doctor
# Должно быть ✅ для Flutter, Xcode, CocoaPods
```

## 3. Запуск проекта

```bash
# Перейдите в проект:
cd /path/to/test-MST/ai-meal-planner

# Установите зависимости:
flutter pub get
cd ios && pod install && cd ..

# Откройте симулятор:
open -a Simulator

# Запустите приложение:
cd /path/to/test-MST
./run_simple.sh ai-meal-planner -d "iPhone 15"
```

**Готово!** 🎉

---

**Если нет скрипта `run_simple.sh`, используйте:**

```bash
cd /path/to/test-MST/ai-meal-planner

# Загрузите .env файл с ключами, затем:
flutter run -d "iPhone 15" \
  --dart-define=APPHUD_API_KEY="..." \
  --dart-define=APPSFLYER_DEV_KEY="..." \
  # ... остальные ключи
```

**Полная инструкция:** `docs/ios_setup_mac.md`
