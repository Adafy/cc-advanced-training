#!/usr/bin/env bash
# install.sh — Idempotent cross-platform installer for Claude Code Advanced Training
# Supports: macOS, Linux (apt/dnf/pacman), Windows (Git Bash / WSL)
# Safe to run multiple times. Skips anything already installed.
set -euo pipefail

# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────
INSTALLED=()
ALREADY_PRESENT=()
FAILED=()
MANUAL_STEPS=()

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
ok()      { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()    { printf "${YELLOW}[SKIP]${NC}  %s\n" "$*"; }
fail()    { printf "${RED}[FAIL]${NC}  %s\n" "$*"; }

check_cmd() {
  command -v "$1" &>/dev/null
}

# ──────────────────────────────────────────────
# OS Detection
# ──────────────────────────────────────────────
detect_os() {
  local uname_out
  uname_out="$(uname -s 2>/dev/null || echo "Unknown")"

  case "$uname_out" in
    Darwin*)  OS="macos" ;;
    Linux*)
      # Check if running inside WSL
      if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
        OS="wsl"
      else
        OS="linux"
      fi
      ;;
    *)
      # Native Windows has no bash — use install.ps1 instead
      fail "This script requires macOS, Linux, or WSL."
      fail "On Windows, run: powershell -ExecutionPolicy Bypass -File install.ps1"
      exit 1
      ;;
  esac

  # Detect Linux package manager
  PKG_MGR="none"
  if [[ "$OS" == "linux" || "$OS" == "wsl" ]]; then
    if check_cmd apt-get; then
      PKG_MGR="apt"
    elif check_cmd dnf; then
      PKG_MGR="dnf"
    elif check_cmd yum; then
      PKG_MGR="yum"
    elif check_cmd pacman; then
      PKG_MGR="pacman"
    elif check_cmd zypper; then
      PKG_MGR="zypper"
    fi
  fi

  ARCH="$(uname -m 2>/dev/null || echo "unknown")"
}

detect_os

echo ""
printf "${BOLD}OS:${NC}       %s\n" "$OS"
printf "${BOLD}Arch:${NC}     %s\n" "$ARCH"
printf "${BOLD}Pkg mgr:${NC}  %s\n" "$PKG_MGR"
echo ""

# ──────────────────────────────────────────────
# Platform-specific install helpers
# ──────────────────────────────────────────────
install_pkg() {
  local macos_name="${1:-}"
  local apt_name="${2:-}"
  local dnf_name="${3:-$apt_name}"

  case "$OS" in
    macos)
      if check_cmd brew; then
        brew install "$macos_name"
      else
        return 1
      fi
      ;;
    linux|wsl)
      case "$PKG_MGR" in
        apt)     sudo apt-get update -qq && sudo apt-get install -y -qq "$apt_name" ;;
        dnf)     sudo dnf install -y "$dnf_name" ;;
        yum)     sudo yum install -y "$dnf_name" ;;
        pacman)  sudo pacman -S --noconfirm "$apt_name" ;;
        zypper)  sudo zypper install -y "$apt_name" ;;
        *)       return 1 ;;
      esac
      ;;
  esac
}

# ──────────────────────────────────────────────
# 1. Homebrew (macOS only)
# ──────────────────────────────────────────────
if [[ "$OS" == "macos" ]]; then
  info "Checking Homebrew..."
  if check_cmd brew; then
    ok "Homebrew already installed: $(brew --version 2>/dev/null | head -1)"
    ALREADY_PRESENT+=("Homebrew")
  else
    info "Installing Homebrew..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
      ok "Homebrew installed: $(brew --version 2>/dev/null | head -1)"
      INSTALLED+=("Homebrew")
    else
      fail "Homebrew installation failed"
      FAILED+=("Homebrew")
      MANUAL_STEPS+=("Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
    fi
  fi
elif [[ "$OS" == "linux" || "$OS" == "wsl" ]]; then
  if [[ "$PKG_MGR" == "none" ]]; then
    fail "No supported package manager found (need apt, dnf, yum, pacman, or zypper)"
    FAILED+=("Package manager")
    MANUAL_STEPS+=("Install a package manager or use a supported Linux distribution")
  else
    ok "Package manager detected: $PKG_MGR"
    ALREADY_PRESENT+=("Package manager ($PKG_MGR)")
  fi
fi

# ──────────────────────────────────────────────
# 2. Git
# ──────────────────────────────────────────────
info "Checking Git..."
if check_cmd git; then
  ok "Git already installed: $(git --version)"
  ALREADY_PRESENT+=("Git")
else
  info "Installing Git..."
  if install_pkg "git" "git" "git"; then
    ok "Git installed: $(git --version)"
    INSTALLED+=("Git")
  else
    fail "Git installation failed"
    FAILED+=("Git")
    case "$OS" in
      macos)     MANUAL_STEPS+=("Install Git: brew install git") ;;
      linux|wsl) MANUAL_STEPS+=("Install Git: sudo apt install git / sudo dnf install git") ;;
    esac
  fi
fi

# ──────────────────────────────────────────────
# 3. Node.js
# ──────────────────────────────────────────────
info "Checking Node.js..."
if check_cmd node; then
  ok "Node.js already installed: node $(node --version)"
  ALREADY_PRESENT+=("Node.js")
else
  info "Installing Node.js..."
  NODE_DONE=false

  # Try nvm first (any platform)
  if check_cmd nvm || [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
    [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]] && source "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    if check_cmd nvm && nvm install --lts; then
      ok "Node.js installed via nvm: node $(node --version)"
      INSTALLED+=("Node.js (via nvm)")
      NODE_DONE=true
    fi
  fi

  # Fallback to platform package manager
  if [[ "$NODE_DONE" == false ]]; then
    case "$OS" in
      macos)
        if check_cmd brew && brew install node; then
          ok "Node.js installed via Homebrew: node $(node --version)"
          INSTALLED+=("Node.js (via Homebrew)")
          NODE_DONE=true
        fi
        ;;
      linux|wsl)
        if install_pkg "" "nodejs" "nodejs"; then
          # Also install npm if separate package
          install_pkg "" "npm" "npm" 2>/dev/null || true
          ok "Node.js installed via $PKG_MGR: node $(node --version 2>/dev/null || echo 'version unknown')"
          INSTALLED+=("Node.js (via $PKG_MGR)")
          NODE_DONE=true
        fi
        ;;
    esac
  fi

  if [[ "$NODE_DONE" == false ]]; then
    fail "Node.js installation failed"
    FAILED+=("Node.js")
    MANUAL_STEPS+=("Install Node.js: https://nodejs.org/ or use nvm: https://github.com/nvm-sh/nvm")
  fi
fi

# ──────────────────────────────────────────────
# 4. Rust toolchain (rustup is cross-platform)
# ──────────────────────────────────────────────
info "Checking Rust toolchain..."
if check_cmd rustc && check_cmd cargo; then
  ok "Rust already installed: $(rustc --version), $(cargo --version)"
  ALREADY_PRESENT+=("Rust")
else
  info "Installing Rust via rustup..."
  RUST_DONE=false

  if check_cmd rustup; then
    # rustup present but toolchain may be missing
    if rustup toolchain install stable; then
      ok "Rust stable toolchain installed: $(rustc --version)"
      INSTALLED+=("Rust (toolchain)")
      RUST_DONE=true
    fi
  else
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
      source "$HOME/.cargo/env" 2>/dev/null || true
      ok "Rust installed: $(rustc --version 2>/dev/null || echo 'restart shell to verify')"
      INSTALLED+=("Rust")
      RUST_DONE=true
    fi
  fi

  if [[ "$RUST_DONE" == false ]]; then
    fail "Rust installation failed"
    FAILED+=("Rust")
    MANUAL_STEPS+=("Install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh")
  fi
fi

# ──────────────────────────────────────────────
# 5. uv (Python package manager — cross-platform)
# ──────────────────────────────────────────────
info "Checking uv..."
if check_cmd uv; then
  ok "uv already installed: $(uv --version)"
  ALREADY_PRESENT+=("uv")
else
  info "Installing uv..."
  UV_DONE=false

  if curl -LsSf https://astral.sh/uv/install.sh | sh; then
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    if check_cmd uv; then
      ok "uv installed: $(uv --version)"
      INSTALLED+=("uv")
      UV_DONE=true
    fi
  fi

  if [[ "$UV_DONE" == false ]]; then
    fail "uv installation failed"
    FAILED+=("uv")
    MANUAL_STEPS+=("Install uv: curl -LsSf https://astral.sh/uv/install.sh | sh")
  fi
fi

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════"
printf "  Installation Summary  (%s / %s)\n" "$OS" "$ARCH"
echo "════════════════════════════════════════════"

if [[ ${#ALREADY_PRESENT[@]} -gt 0 ]]; then
  printf "${GREEN}Already present:${NC}\n"
  for item in "${ALREADY_PRESENT[@]}"; do
    echo "  - $item"
  done
fi

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
  printf "${GREEN}Newly installed:${NC}\n"
  for item in "${INSTALLED[@]}"; do
    echo "  - $item"
  done
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
  printf "${RED}Failed:${NC}\n"
  for item in "${FAILED[@]}"; do
    echo "  - $item"
  done
fi

if [[ ${#MANUAL_STEPS[@]} -gt 0 ]]; then
  echo ""
  printf "${YELLOW}Manual steps required:${NC}\n"
  for step in "${MANUAL_STEPS[@]}"; do
    echo "  - $step"
  done
fi

echo "════════════════════════════════════════════"

# Exit with error if anything failed
if [[ ${#FAILED[@]} -gt 0 ]]; then
  exit 1
fi
exit 0
