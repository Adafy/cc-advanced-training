---
name: install
description: Install all required tools and software for the Claude Code Advanced Training project. Use when the user wants to set up their development environment, install prerequisites, run /install, or mentions needing Node.js, Rust, uv, Git for this project. Also use when the user mentions setup issues, missing dependencies, or environment problems. Does NOT install Claude Code plugins — use /install_plugins for that.
user-invocable: true
allowed-tools: Bash, Read
disable-model-invocation: true
---

# Install — Claude Code Advanced Training Prerequisites

Set up the development environment for the Claude Code Advanced Training project. The bundled script auto-detects the operating system (macOS, Linux, Windows/WSL) and uses the appropriate package manager.

## Supported Platforms

| OS | Package managers used |
|----|---------------------|
| macOS | Homebrew, rustup, nvm |
| Linux | apt / dnf / yum / pacman / zypper, rustup, nvm |
| Windows (Git Bash) | winget / choco / scoop, rustup |
| WSL | Same as Linux |

## Required Prerequisites (from training slide 5)

1. **Platform package manager** — Homebrew (macOS), apt/dnf/pacman (Linux), winget/choco/scoop (Windows)
2. **Git** — version control
3. **Node.js** — for TypeScript frontend and npx commands
4. **Rust toolchain** (rustc + cargo via rustup) — for Rust web server backend
5. **uv** — Python package manager for running ADW scripts

## Execution Steps

### Step 1: Detect OS and run the correct install script

There are two scripts — pick the right one for the platform. Both are idempotent: they check each tool first, install only what's missing, and print a summary.

**macOS / Linux / WSL** — run the bash script:
```bash
bash .claude/skills/install/scripts/install.sh
```

**Windows (native PowerShell)** — run the PowerShell script:
```powershell
powershell -ExecutionPolicy Bypass -File .claude/skills/install/scripts/install.ps1
```

To detect which to use, run `uname -s` via Bash. If it returns `Darwin` or `Linux`, use install.sh. If the Bash tool is unavailable or returns `MINGW`/`MSYS`/`CYGWIN`, or if you know the user is on Windows, use install.ps1 via PowerShell.

If you cannot determine the project root, use the absolute path to the script.

### Step 2: Show manual installation instructions

After all automated steps complete, display any remaining manual steps:

1. **Shell restart** — if any tools were newly installed (especially Rust or uv), remind to restart the terminal or source the shell profile

**Important:** Do NOT install Claude Code plugins at this stage. Plugins (superpowers, skill-creator, code-simplifier) are only needed for Action Pack 2. When trainees are ready for Action Pack 2, they should run `/install_plugins` then — not now.

## Output Format

End with a clear summary:

```
== Setup Summary (os / arch) ==
Already present: [list]
Newly installed: [list]
Failed: [list, if any]

== Manual Steps Required ==
- [any steps the user needs to do manually]
```
