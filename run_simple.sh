#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    local ps_args=""
    local arg
    for arg in "$@"; do
      ps_args+=" $arg"
    done
    powershell.exe -NoProfile -Command "Set-Location '$win_dir'; & '$win_flutter_bat'$ps_args"
    return
  fi

  echo "Flutter not found."
  echo "Install Flutter or make sure one of these is available:"
  echo "  - native 'flutter' command in PATH"
  echo "  - 'flutter.bat' in Windows PATH (for WSL fallback)"
  echo "  - FLUTTER_BAT_PATH environment variable set to Windows flutter.bat path"
  exit 1
}

main() {
  select_app "${1:-}"
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
  run_flutter_in_dir "$app_dir" run
}

main "${1:-}"
