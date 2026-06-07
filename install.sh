#!/bin/sh
# aicli installer
# Works on: macOS · Linux · iOS iSH · Android Termux
# Usage:  sh install.sh
set -e

PROG="aicli"
REPO_SCRIPT="$(cd "$(dirname "$0")" && pwd)/aicli"

# ── Detect OS ──────────────────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s 2>/dev/null)" in
    Darwin) echo "macos" ;;
    Linux)
      [ -e /proc/ish ] && echo "ios_ish" && return
      case "${PREFIX:-}" in *termux*) echo "android_termux" && return ;; esac
      [ -d /data/data/com.termux ] && echo "android_termux" && return
      echo "linux" ;;
    *) echo "unknown" ;;
  esac
}
OS=$(detect_os)

# ── Pick writable install directory ───────────────────────────────────────────
pick_dir() {
  for d in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
    if [ -d "$d" ] && [ -w "$d" ]; then echo "$d"; return; fi
    if [ ! -e "$d" ]; then
      mkdir -p "$d" 2>/dev/null && echo "$d" && return
    fi
  done
  mkdir -p "$HOME/.local/bin"
  echo "$HOME/.local/bin"
}
INSTALL_DIR=$(pick_dir)
DEST="${INSTALL_DIR}/${PROG}"

# ── Check bash ─────────────────────────────────────────────────────────────────
BASH_BIN="$(command -v bash 2>/dev/null || true)"
if [ -z "$BASH_BIN" ]; then
  echo "bash not found. Install it first:"
  case "$OS" in
    macos)          echo "  brew install bash" ;;
    linux)          echo "  sudo apt install bash  # or: sudo yum install bash" ;;
    ios_ish)        echo "  apk add bash" ;;
    android_termux) echo "  pkg install bash" ;;
  esac
  exit 1
fi
echo "✓ bash: $($BASH_BIN --version | head -1)"

# ── Check curl ─────────────────────────────────────────────────────────────────
if ! command -v curl >/dev/null 2>&1; then
  echo "curl not found. Install it first:"
  case "$OS" in
    macos)          echo "  brew install curl" ;;
    linux)          echo "  sudo apt install curl" ;;
    ios_ish)        echo "  apk add curl" ;;
    android_termux) echo "  pkg install curl" ;;
  esac
  exit 1
fi
echo "✓ curl: $(curl --version | head -1 | cut -d' ' -f1-2)"

# ── Check jq ──────────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  echo ""
  echo "⚠  jq not found (required for JSON parsing). Install:"
  case "$OS" in
    macos)          echo "  brew install jq" ;;
    linux)          echo "  sudo apt install jq  # or: sudo yum install jq" ;;
    ios_ish)        echo "  apk add jq" ;;
    android_termux) echo "  pkg install jq" ;;
  esac
  echo ""
  echo "Then re-run this installer."
  exit 1
fi
echo "✓ jq:   $(jq --version)"

# ── Install ────────────────────────────────────────────────────────────────────
if [ -f "$REPO_SCRIPT" ]; then
  cp "$REPO_SCRIPT" "$DEST"
else
  echo "Could not find aicli script in the same directory as install.sh"
  exit 1
fi

# Patch shebang to use the found bash
# macOS uses BSD sed, Linux uses GNU sed
case "$OS" in
  macos) sed -i '' "1s|.*|#!${BASH_BIN}|" "$DEST" ;;
  *)     sed -i    "1s|.*|#!${BASH_BIN}|" "$DEST" ;;
esac

chmod +x "$DEST"
echo "✓ Installed: $DEST"

# ── PATH check ─────────────────────────────────────────────────────────────────
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*) ;;
  *)
    echo ""
    echo "⚠  ${INSTALL_DIR} is not in your PATH."
    echo "   Add to your shell config (~/.zshrc, ~/.bashrc, ~/.profile):"
    echo ""
    echo "   export PATH=\"${INSTALL_DIR}:\$PATH\""
    echo ""
    ;;
esac

# ── Quick start ────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────"
echo " Quick start"
echo "─────────────────────────────────────"
echo ""
echo "  # Set your API key (pick your provider):"
echo "  aicli config --set anthropic.api_key=sk-ant-..."
echo "  aicli config --set deepseek.api_key=..."
echo ""
echo "  # Command mode (default):"
echo "  aicli \"list docker containers sorted by memory\""
echo "  aicli --confirm \"delete tmp files older than 7 days\""
echo ""
echo "  # Script mode:"
echo "  aicli -m script \"backup postgres database to S3\""
echo "  aicli -m script --lang py \"parse nginx logs and plot request rate\""
echo ""
echo "  # Chat mode:"
echo "  aicli -m chat"
echo "  aicli -m chat --session work \"explain kubernetes ingress\""
echo ""
echo "  # Check environment & providers:"
echo "  aicli check"
echo ""
