# Быстрая установка на Mac для iOS тестирования

## Шаг 1: Установка Xcode (обязательно)

1. Откройте **App Store** на Mac
2. Найдите **Xcode** (бесплатно)
3. Нажмите **Установить** (займет ~10-15 минут, ~12GB)
4. После установки откройте Xcode один раз и примите лицензию:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

## Шаг 2: Установка Flutter

### Вариант A: Через Homebrew (рекомендуется)

```bash
# Установите Homebrew, если его нет:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Установите Flutter:
brew install --cask flutter
```

### Вариант B: Вручную

```bash
# Скачайте Flutter SDK:
cd ~
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"

# Добавьте в ~/.zshrc (или ~/.bash_profile):
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

### Проверка установки:

```bash
flutter doctor
```

**Важно:** Должно быть ✅ для:
- ✅ Flutter (Channel stable)
- ✅ Xcode - develop for iOS
- ✅ CocoaPods - CocoaPods installed

Если есть ❌, выполните:
```bash
flutter doctor --android-licenses  # если нужно
sudo gem install cocoapods         # если CocoaPods не установлен
```

## Шаг 3: Настройка iOS Simulator

1. Откройте **Xcode**
2. **Xcode → Settings → Platforms** (или **Components**)
3. Убедитесь, что установлен **iOS Simulator** (обычно уже есть)

Или через терминал:
```bash
open -a Simulator
```

## Шаг 4: Подготовка проекта

1. **Скопируйте проект** на Mac (через Git, USB, или облако)

2. **Создайте `.env` файл** в корне проекта `ai-meal-planner/`:
   ```bash
   cd /path/to/test-MST/ai-meal-planner
   # Создайте .env файл с вашими ключами (скопируйте с Windows)
   ```

3. **Установите зависимости:**
   ```bash
   cd /path/to/test-MST/ai-meal-planner
   flutter pub get
   ```

4. **Установите iOS зависимости (CocoaPods):**
   ```bash
   cd ios
   pod install
   cd ..
   ```

## Шаг 5: Запуск на iOS Simulator

### Вариант A: Через скрипт (если есть .env в корне test-MST)

```bash
cd /path/to/test-MST
./run_simple.sh ai-meal-planner -d "iPhone 15"
```

### Вариант B: Прямой запуск Flutter

```bash
cd /path/to/test-MST/ai-meal-planner

# Сначала откройте Simulator:
open -a Simulator

# Затем запустите приложение:
flutter run -d "iPhone 15"
```

### Вариант C: С указанием .env файла

```bash
cd /path/to/test-MST
./run_simple.sh --env /path/to/.env ai-meal-planner -d "iPhone 15"
```

## Шаг 6: Проверка устройств

Посмотреть доступные iOS симуляторы:
```bash
flutter devices
```

Пример вывода:
```
iPhone 15 Pro (simulator) • 12345678-1234-1234-1234-123456789ABC • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-0 (simulator)
```

## Возможные проблемы

### ❌ "CocoaPods not installed"
```bash
sudo gem install cocoapods
cd ios
pod install
```

### ❌ "No iOS devices found"
```bash
open -a Simulator
# Подождите, пока симулятор загрузится, затем:
flutter devices
```

### ❌ "Signing for Runner requires a development team"
1. Откройте `ios/Runner.xcworkspace` в Xcode
2. Выберите **Runner** в навигаторе слева
3. Вкладка **Signing & Capabilities**
4. Поставьте галочку **Automatically manage signing**
5. Выберите свою **Team** (или создайте бесплатный Apple ID)

### ❌ "Command PhaseScriptExecution failed"
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

## Быстрая проверка (чеклист)

- [ ] Xcode установлен и открыт хотя бы раз
- [ ] Flutter установлен (`flutter --version`)
- [ ] `flutter doctor` показывает ✅ для iOS
- [ ] CocoaPods установлен (`pod --version`)
- [ ] `.env` файл создан в `ai-meal-planner/` или указан через `--env`
- [ ] iOS Simulator открыт (`open -a Simulator`)
- [ ] `flutter devices` показывает iOS симулятор
- [ ] `flutter run` запускает приложение

## Что проверить после запуска

1. **Приложение открылось** на симуляторе
2. **ATT запрос появился** (если включен)
3. **В Profile Page** видны статусы сервисов:
   - AppHud: статус подключения
   - AppsFlyer: статус инициализации
   - AppMetrica: статус
   - AdMob: статус
4. **Нет критических ошибок** в консоли

---

**Время установки:** ~20-30 минут (в основном загрузка Xcode)

**Минимальные требования:**
- macOS 12.0 или новее
- ~15GB свободного места (для Xcode)
- Интернет для загрузки
