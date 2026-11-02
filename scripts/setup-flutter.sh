#!/usr/bin/env bash
# Instala e configura Flutter + Android SDK em Arch/CachyOS.
# Uso: bash scripts/setup-flutter.sh
set -euo pipefail

echo "==> Dependencias do sistema"
sudo pacman -S --needed --noconfirm \
  base-devel git curl unzip zip xz \
  clang cmake ninja pkgconf gtk3 \
  jdk17-openjdk

# ---------------------------------------------------------------- Flutter
FLUTTER_HOME="$HOME/development/flutter"
if [ ! -d "$FLUTTER_HOME/.git" ]; then
  echo "==> Clonando Flutter stable em $FLUTTER_HOME"
  mkdir -p "$HOME/development"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

# PATH permanente no fish (shell padrao) e no bash
fish -c "fish_add_path -U $FLUTTER_HOME/bin" >/dev/null 2>&1 || true
grep -q "development/flutter/bin" "$HOME/.bashrc" 2>/dev/null || \
  printf '%s\n' 'export PATH="$HOME/development/flutter/bin:$PATH"' >> "$HOME/.bashrc"

# ------------------------------------------------------------ Android SDK
ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"
mkdir -p "$ANDROID_HOME/cmdline-tools"

if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "==> Instalando Android command-line tools"
  BUILD=$(curl -fsSL https://dl.google.com/android/repository/repository2-1.xml \
    | grep -o 'commandlinetools-linux-[0-9]*_latest.zip' \
    | sed -E 's/.*-([0-9]+)_latest.zip/\1/' \
    | sort -n | tail -1)
  curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${BUILD}_latest.zip" \
    -o /tmp/android-cmdline-tools.zip
  rm -rf "$ANDROID_HOME/cmdline-tools/latest" "$ANDROID_HOME/cmdline-tools/cmdline-tools"
  unzip -q /tmp/android-cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -f /tmp/android-cmdline-tools.zip
fi
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "==> Aceitando licencas e instalando pacotes Android"
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0"

# Variaveis permanentes no fish e no bash
fish -c "set -Ux ANDROID_HOME $ANDROID_HOME; set -Ux ANDROID_SDK_ROOT $ANDROID_HOME; fish_add_path -U $ANDROID_HOME/cmdline-tools/latest/bin $ANDROID_HOME/platform-tools" >/dev/null 2>&1 || true
if ! grep -q "ANDROID_HOME" "$HOME/.bashrc" 2>/dev/null; then
  {
    printf '%s\n' 'export ANDROID_HOME="$HOME/Android/Sdk"'
    printf '%s\n' 'export ANDROID_SDK_ROOT="$ANDROID_HOME"'
    printf '%s\n' 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"'
  } >> "$HOME/.bashrc"
fi

# ------------------------------------------------------------- Config final
echo "==> Configurando Flutter"
git config --global --add safe.directory "$FLUTTER_HOME" 2>/dev/null || true
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --android-sdk "$ANDROID_HOME" >/dev/null 2>&1 || true
flutter precache --android --linux >/dev/null 2>&1 || true

echo
echo "==> Versoes instaladas"
flutter --version
echo
echo "==> Diagnostico"
flutter doctor

echo
echo "Pronto. Abra um terminal novo (ou rode: fish_add_path -U $HOME/development/flutter/bin $HOME/Android/Sdk/platform-tools) e depois: flutter doctor"
