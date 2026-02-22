#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

load_env_file() {
  local env_file="$1"
  if [[ ! -f "$env_file" ]]; then
    return 0
  fi
  set -a
  # Support UTF-8 BOM and CRLF line endings (common on Windows).
  # shellcheck disable=SC1090
  . <(
    sed -e $'1s/^\xEF\xBB\xBF//' -e 's/\r$//' "$env_file" \
      | sed -E \
          -e 's/^[[:space:]]*export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=/export \1=/' \
          -e 's/^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=/\1=/' \
          -e 's/^[[:space:]]+//' \
          -e 's/[[:space:]]+$//'
  )
  set +a
}

DEBUG_ENV="${DEBUG_ENV:-false}"
DEBUG_ONLY="${DEBUG_ONLY:-false}"
ENV_FILE_OVERRIDE=""

env_len() {
  local v="${1-}"
  echo "${#v}"
}

env_is_set() {
  local v="${1-}"
  [[ -n "$v" ]]
}

file_value_len() {
  local file="$1"
  local key="$2"
  if [[ -z "$file" ]] || [[ ! -f "$file" ]]; then
    echo "0"
    return 0
  fi
  # Extract the first matching key=VALUE line (after basic normalization), then measure VALUE length.
  local line
  line="$(
    sed -e $'1s/^\xEF\xBB\xBF//' -e 's/\r$//' "$file" \
      | sed -E \
          -e 's/^[[:space:]]*#.*$//' \
          -e 's/^[[:space:]]*$//' \
          -e 's/^[[:space:]]*export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=/export \1=/' \
          -e 's/^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=/\1=/' \
      | grep -E "^${key}=" \
      | head -n 1
  )"
  if [[ -z "$line" ]]; then
    echo "0"
    return 0
  fi
  local value="${line#*=}"
  echo "${#value}"
}

maybe_debug_env() {
  if [[ "$DEBUG_ENV" != "true" ]]; then
    return 0
  fi
  echo "-----------------------------------------"
  echo " DEBUG_ENV enabled"
  echo " Loaded env file: ${ENV_FILE_OVERRIDE:-$ROOT_DIR/.env}"
  local env_file="${ENV_FILE_OVERRIDE:-$ROOT_DIR/.env}"
  echo " APPHUD_API_KEY: $(env_is_set "${APPHUD_API_KEY-}" && echo set || echo missing) (len=$(env_len "${APPHUD_API_KEY-}"), file_len=$(file_value_len "$env_file" "APPHUD_API_KEY"))"
  echo " APPSFLYER_DEV_KEY: $(env_is_set "${APPSFLYER_DEV_KEY-}" && echo set || echo missing) (len=$(env_len "${APPSFLYER_DEV_KEY-}"), file_len=$(file_value_len "$env_file" "APPSFLYER_DEV_KEY"))"
  echo " APPMETRICA_API_KEY: $(env_is_set "${APPMETRICA_API_KEY-}" && echo set || echo missing) (len=$(env_len "${APPMETRICA_API_KEY-}"), file_len=$(file_value_len "$env_file" "APPMETRICA_API_KEY"))"
  echo " ADMOB_APP_ID: $(env_is_set "${ADMOB_APP_ID-}" && echo set || echo missing) (len=$(env_len "${ADMOB_APP_ID-}"), file_len=$(file_value_len "$env_file" "ADMOB_APP_ID"))"
  echo " ENABLE_EXTERNAL_SERVICES: ${ENABLE_EXTERNAL_SERVICES-<unset>}"
  echo "-----------------------------------------"
}

REMAINING_ARGS=()
parse_env_args() {
  # Supports:
  #   ./run_simple.sh --env /path/to/.env
  #   ./run_simple.sh /path/to/.env
  #   ./run_simple.sh --debug-only ...
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --debug-env)
        DEBUG_ENV="true"
        shift 1
        ;;
      --debug-only)
        DEBUG_ONLY="true"
        DEBUG_ENV="true"
        shift 1
        ;;
      --env)
        if [[ $# -lt 2 ]] || [[ -z "${2:-}" ]]; then
          echo "Missing value for --env"
          exit 1
        fi
        ENV_FILE_OVERRIDE="${2:-}"
        shift 2
        ;;
      *.env)
        if [[ -f "$1" ]]; then
          ENV_FILE_OVERRIDE="$1"
          shift 1
        else
          break
        fi
        ;;
      *)
        break
        ;;
    esac
  done
  REMAINING_ARGS=("$@")
}

parse_env_args "$@"

# Load local .env if present (not committed to git, see .gitignore), or an override.
if [[ -n "$ENV_FILE_OVERRIDE" ]]; then
  load_env_file "$ENV_FILE_OVERRIDE"
  maybe_debug_env
else
  load_env_file "$ROOT_DIR/.env"
  maybe_debug_env
fi

if [[ "$DEBUG_ONLY" == "true" ]]; then
  echo "DEBUG_ONLY: exiting before launching Flutter."
  exit 0
fi
APPS=(
  "ball-physics"
  "aviation-game"
  "animals-encyclopedia"
  "education-subjects"
  "time-management"
  "utility-app"
  "ai-meal-planner"
)

# Variable to store the selected app
SELECTED_APP=""

is_valid_app() {
  local app="$1"
  for item in "${APPS[@]}"; do
    if [[ "$item" == "$app" ]]; then
      return 0
    fi
  done
  return 1
}

select_app() {
  local arg="${1:-}"
  if [[ -n "$arg" ]]; then
    if ! is_valid_app "$arg"; then
      echo "Unknown app: $arg"
      echo "Available apps: ${APPS[*]}"
      exit 1
    fi
    SELECTED_APP="$arg"
    return
  fi

  echo "========================================="
  echo " Flutter App Launcher"
  echo "========================================="
  echo "Choose app to run:"
  local i=1
  for app in "${APPS[@]}"; do
    echo "  $i) $app"
    ((i++))
  done
  echo
  read -r -p "Enter number [1-${#APPS[@]}]: " idx
  if [[ ! "$idx" =~ ^[0-9]+$ ]] || (( idx < 1 || idx > ${#APPS[@]} )); then
    echo "Invalid choice"
    exit 1
  fi
  SELECTED_APP="${APPS[$((idx - 1))]}"
}

find_windows_flutter_bat() {
  if [[ -n "${FLUTTER_BAT_PATH:-}" ]]; then
    if [[ "${FLUTTER_BAT_PATH}" == /mnt/* ]]; then
      wslpath -w "${FLUTTER_BAT_PATH}"
    else
      echo "${FLUTTER_BAT_PATH}"
    fi
    return 0
  fi

  if command -v powershell.exe >/dev/null 2>&1; then
    local flutter_path
    flutter_path=$(powershell.exe -NoProfile -Command "(Get-Command flutter.bat -ErrorAction SilentlyContinue).Path")
    if [[ -n "$flutter_path" ]]; then
      echo "$flutter_path" | tr -d '\r'
      return 0
    fi
  fi
  return 1
}

has_native_flutter() {
  command -v flutter >/dev/null 2>&1
}

native_flutter_is_windows_mount() {
  if ! has_native_flutter; then
    return 1
  fi
  local flutter_bin
  flutter_bin="$(command -v flutter)"
  [[ "$flutter_bin" == /mnt/c/* ]]
}

run_flutter_in_dir() {
  local app_dir="$1"
  shift

  if has_native_flutter && ! native_flutter_is_windows_mount; then
    (
      cd "$app_dir"
      flutter "$@"
    )
    return
  fi

  local win_flutter_bat
  if win_flutter_bat=$(find_windows_flutter_bat); then
    if ! command -v wslpath >/dev/null 2>&1; then
      echo "wslpath is required for Windows Flutter fallback."
      exit 1
    fi
    local win_dir
    win_dir="$(wslpath -w "$app_dir")"
    local tmp_args
    tmp_args="$(mktemp)"
    printf '%s\n' "$@" > "$tmp_args"
    local win_args
    win_args="$(wslpath -w "$tmp_args")"
    powershell.exe -NoProfile -Command "Set-Location '$win_dir'; \$argList = Get-Content -LiteralPath '$win_args'; if (\$argList -is [string]) { \$argList = @(\$argList) }; & '$win_flutter_bat' @argList"
    rm -f "$tmp_args"
    return
  fi

  echo "Flutter not found."
  echo "Install Flutter or make sure one of these is available:"
  echo "  - native 'flutter' command in PATH"
  echo "  - 'flutter.bat' in Windows PATH (for WSL fallback)"
  echo "  - FLUTTER_BAT_PATH environment variable set to Windows flutter.bat path"
  exit 1
}

run_ai_meal_planner() {
  local app_dir="$1"
  shift || true
  local extra_args=("$@")

  # Allow app-specific overrides when a .env sits inside the app folder.
  load_env_file "$app_dir/.env"
  maybe_debug_env

  # Allow overriding via environment only; do not bake secrets into the script.
  local apphud_api_key="${APPHUD_API_KEY:-}"
  local apphud_placement_id="${APPHUD_PLACEMENT_ID:-}"
  local apphud_paywall_id="${APPHUD_PAYWALL_ID:-}"
  local apphud_weekly="${APPHUD_PRODUCT_WEEKLY:-}"
  local apphud_monthly="${APPHUD_PRODUCT_MONTHLY:-}"

  local appsflyer_dev_key="${APPSFLYER_DEV_KEY:-}"
  local appsflyer_apple_id="${APPSFLYER_APPLE_APP_ID:-}"
  local appsflyer_att_wait="${APPSFLYER_ATT_WAIT_SECONDS:-12}"

  local appmetrica_api_key="${APPMETRICA_API_KEY:-}"

  local freepik_api_key="${FREEPIK_API_KEY:-}"
  local enable_freepik_tools="${ENABLE_FREEPIK_TOOLS:-false}"
  local enable_ads="${ENABLE_ADS:-false}"

  local admob_app_id="${ADMOB_APP_ID:-}"
  local admob_banner="${ADMOB_BANNER_AD_UNIT_ID:-}"
  local admob_interstitial="${ADMOB_INTERSTITIAL_AD_UNIT_ID:-}"
  local admob_rewarded="${ADMOB_REWARDED_AD_UNIT_ID:-}"
  local admob_rewarded_interstitial="${ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ID:-}"
  local admob_app_open="${ADMOB_APP_OPEN_AD_UNIT_ID:-}"
  local admob_native="${ADMOB_NATIVE_AD_UNIT_ID:-}"

  local enable_external_services="${ENABLE_EXTERNAL_SERVICES:-true}"
  local enable_firebase_analytics="${ENABLE_FIREBASE_ANALYTICS:-false}"
  local firebase_android_api_key="${FIREBASE_ANDROID_API_KEY:-}"
  local firebase_android_app_id="${FIREBASE_ANDROID_APP_ID:-}"
  local firebase_android_project_id="${FIREBASE_ANDROID_PROJECT_ID:-}"
  local firebase_android_sender_id="${FIREBASE_ANDROID_SENDER_ID:-}"
  local firebase_android_storage_bucket="${FIREBASE_ANDROID_STORAGE_BUCKET:-}"
  local firebase_ios_api_key="${FIREBASE_IOS_API_KEY:-}"
  local firebase_ios_app_id="${FIREBASE_IOS_APP_ID:-}"
  local firebase_ios_project_id="${FIREBASE_IOS_PROJECT_ID:-}"
  local firebase_ios_sender_id="${FIREBASE_IOS_SENDER_ID:-}"
  local firebase_ios_bundle_id="${FIREBASE_IOS_BUNDLE_ID:-}"
  local firebase_ios_storage_bucket="${FIREBASE_IOS_STORAGE_BUCKET:-}"

  run_flutter_in_dir "$app_dir" run \
    --dart-define=APPHUD_API_KEY="$apphud_api_key" \
    --dart-define=APPHUD_PLACEMENT_ID="$apphud_placement_id" \
    --dart-define=APPHUD_PAYWALL_ID="$apphud_paywall_id" \
    --dart-define=APPHUD_PRODUCT_WEEKLY="$apphud_weekly" \
    --dart-define=APPHUD_PRODUCT_MONTHLY="$apphud_monthly" \
    --dart-define=APPSFLYER_DEV_KEY="$appsflyer_dev_key" \
    --dart-define=APPSFLYER_APPLE_APP_ID="$appsflyer_apple_id" \
    --dart-define=APPSFLYER_ATT_WAIT_SECONDS="$appsflyer_att_wait" \
    --dart-define=APPMETRICA_API_KEY="$appmetrica_api_key" \
    --dart-define=ENABLE_EXTERNAL_SERVICES="$enable_external_services" \
    --dart-define=ADMOB_APP_ID="$admob_app_id" \
    --dart-define=ADMOB_BANNER_AD_UNIT_ID="$admob_banner" \
    --dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID="$admob_interstitial" \
    --dart-define=ADMOB_REWARDED_AD_UNIT_ID="$admob_rewarded" \
    --dart-define=ADMOB_REWARDED_INTERSTITIAL_AD_UNIT_ID="$admob_rewarded_interstitial" \
    --dart-define=ADMOB_APP_OPEN_AD_UNIT_ID="$admob_app_open" \
    --dart-define=ADMOB_NATIVE_AD_UNIT_ID="$admob_native" \
    --dart-define=ENABLE_FIREBASE_ANALYTICS="$enable_firebase_analytics" \
    --dart-define=FIREBASE_ANDROID_API_KEY="$firebase_android_api_key" \
    --dart-define=FIREBASE_ANDROID_APP_ID="$firebase_android_app_id" \
    --dart-define=FIREBASE_ANDROID_PROJECT_ID="$firebase_android_project_id" \
    --dart-define=FIREBASE_ANDROID_SENDER_ID="$firebase_android_sender_id" \
    --dart-define=FIREBASE_ANDROID_STORAGE_BUCKET="$firebase_android_storage_bucket" \
    --dart-define=FIREBASE_IOS_API_KEY="$firebase_ios_api_key" \
    --dart-define=FIREBASE_IOS_APP_ID="$firebase_ios_app_id" \
    --dart-define=FIREBASE_IOS_PROJECT_ID="$firebase_ios_project_id" \
    --dart-define=FIREBASE_IOS_SENDER_ID="$firebase_ios_sender_id" \
    --dart-define=FIREBASE_IOS_BUNDLE_ID="$firebase_ios_bundle_id" \
    --dart-define=FIREBASE_IOS_STORAGE_BUCKET="$firebase_ios_storage_bucket" \
    --dart-define=FREEPIK_API_KEY="$freepik_api_key" \
    --dart-define=ENABLE_FREEPIK_TOOLS="$enable_freepik_tools" \
    --dart-define=ENABLE_ADS="$enable_ads" \
    "${extra_args[@]}"
}

main() {
  select_app "${1:-}"
  shift || true
  local flutter_extra_args=("$@")
  local app="$SELECTED_APP"
  local app_dir="$ROOT_DIR/$app"

  if [[ ! -f "$app_dir/pubspec.yaml" ]]; then
    echo "pubspec.yaml not found in: $app_dir"
    exit 1
  fi

  echo
  echo "========================================="
  echo " Starting: $app"
  echo "========================================="

  echo "[1/3] Installing dependencies..."
  run_flutter_in_dir "$app_dir" pub get

  echo "[2/3] Checking devices..."
  run_flutter_in_dir "$app_dir" devices || true

  echo "[3/3] Running app..."
  if [[ "$app" == "ai-meal-planner" ]]; then
    run_ai_meal_planner "$app_dir" "${flutter_extra_args[@]}"
  else
    run_flutter_in_dir "$app_dir" run "${flutter_extra_args[@]}"
  fi
}

main "${REMAINING_ARGS[@]}"
