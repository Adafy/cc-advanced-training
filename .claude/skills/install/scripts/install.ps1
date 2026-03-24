# install.ps1 — Idempotent installer for Claude Code Advanced Training (Windows/PowerShell)
# Safe to run multiple times. Skips anything already installed.
#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────
$Installed = @()
$AlreadyPresent = @()
$Failed = @()
$ManualSteps = @()

function Write-Info  { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "[OK]    $msg" -ForegroundColor Green }
function Write-Skip  { param($msg) Write-Host "[SKIP]  $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "[FAIL]  $msg" -ForegroundColor Red }

function Test-Command {
    param($Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# ──────────────────────────────────────────────
# OS Detection
# ──────────────────────────────────────────────
$OS = "windows"
$Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

# Detect package manager
$PkgMgr = "none"
if (Test-Command "winget") { $PkgMgr = "winget" }
elseif (Test-Command "choco") { $PkgMgr = "choco" }
elseif (Test-Command "scoop") { $PkgMgr = "scoop" }

Write-Host ""
Write-Host "OS:       $OS" -ForegroundColor White
Write-Host "Arch:     $Arch" -ForegroundColor White
Write-Host "Pkg mgr:  $PkgMgr" -ForegroundColor White
Write-Host ""

if ($PkgMgr -eq "none") {
    Write-Skip "No package manager found (winget, choco, or scoop recommended)"
    $ManualSteps += "Install a package manager: winget (built-in on Win 10+), choco (chocolatey.org), or scoop (scoop.sh)"
} else {
    Write-Ok "Package manager detected: $PkgMgr"
    $AlreadyPresent += "Package manager ($PkgMgr)"
}

# ──────────────────────────────────────────────
# 1. Git
# ──────────────────────────────────────────────
Write-Info "Checking Git..."
if (Test-Command "git") {
    $gitVer = git --version 2>&1
    Write-Ok "Git already installed: $gitVer"
    $AlreadyPresent += "Git"
} else {
    Write-Info "Installing Git..."
    $gitDone = $false
    switch ($PkgMgr) {
        "winget" {
            winget install --silent --accept-package-agreements Git.Git
            if ($LASTEXITCODE -eq 0) { Write-Ok "Git installed via winget"; $Installed += "Git"; $gitDone = $true }
        }
        "choco" {
            choco install -y git
            if ($LASTEXITCODE -eq 0) { Write-Ok "Git installed via choco"; $Installed += "Git"; $gitDone = $true }
        }
        "scoop" {
            scoop install git
            if ($LASTEXITCODE -eq 0) { Write-Ok "Git installed via scoop"; $Installed += "Git"; $gitDone = $true }
        }
    }
    if (-not $gitDone) {
        Write-Fail "Git installation failed"
        $Failed += "Git"
        $ManualSteps += "Install Git: https://git-scm.com/download/win"
    }
}

# ──────────────────────────────────────────────
# 2. Node.js
# ──────────────────────────────────────────────
Write-Info "Checking Node.js..."
if (Test-Command "node") {
    $nodeVer = node --version 2>&1
    Write-Ok "Node.js already installed: node $nodeVer"
    $AlreadyPresent += "Node.js"
} else {
    Write-Info "Installing Node.js..."
    $nodeDone = $false
    switch ($PkgMgr) {
        "winget" {
            winget install --silent --accept-package-agreements OpenJS.NodeJS.LTS
            if ($LASTEXITCODE -eq 0) { Write-Ok "Node.js installed via winget"; $Installed += "Node.js"; $nodeDone = $true }
        }
        "choco" {
            choco install -y nodejs-lts
            if ($LASTEXITCODE -eq 0) { Write-Ok "Node.js installed via choco"; $Installed += "Node.js"; $nodeDone = $true }
        }
        "scoop" {
            scoop install nodejs-lts
            if ($LASTEXITCODE -eq 0) { Write-Ok "Node.js installed via scoop"; $Installed += "Node.js"; $nodeDone = $true }
        }
    }
    if (-not $nodeDone) {
        Write-Fail "Node.js installation failed"
        $Failed += "Node.js"
        $ManualSteps += "Install Node.js: https://nodejs.org/"
    }
}

# ──────────────────────────────────────────────
# 3. Rust toolchain
# ──────────────────────────────────────────────
Write-Info "Checking Rust toolchain..."
if ((Test-Command "rustc") -and (Test-Command "cargo")) {
    $rustVer = rustc --version 2>&1
    $cargoVer = cargo --version 2>&1
    Write-Ok "Rust already installed: $rustVer, $cargoVer"
    $AlreadyPresent += "Rust"
} else {
    Write-Info "Installing Rust via rustup..."
    $rustDone = $false

    if (Test-Command "rustup") {
        rustup toolchain install stable
        if ($LASTEXITCODE -eq 0) { Write-Ok "Rust stable toolchain installed"; $Installed += "Rust (toolchain)"; $rustDone = $true }
    } else {
        switch ($PkgMgr) {
            "winget" {
                winget install --silent --accept-package-agreements Rustlang.Rustup
                if ($LASTEXITCODE -eq 0) {
                    Write-Ok "Rustup installed via winget (restart shell, then run: rustup toolchain install stable)"
                    $Installed += "Rustup"
                    $ManualSteps += "After restarting shell, run: rustup toolchain install stable"
                    $rustDone = $true
                }
            }
            default {
                # Download rustup-init.exe
                $rustupUrl = "https://win.rustup.rs/x86_64"
                $rustupExe = "$env:TEMP\rustup-init.exe"
                try {
                    Invoke-WebRequest -Uri $rustupUrl -OutFile $rustupExe -UseBasicParsing
                    & $rustupExe -y
                    if ($LASTEXITCODE -eq 0) {
                        Write-Ok "Rust installed (restart shell to use)"
                        $Installed += "Rust"
                        $rustDone = $true
                    }
                } catch {
                    # fall through to failure
                }
            }
        }
    }
    if (-not $rustDone) {
        Write-Fail "Rust installation failed"
        $Failed += "Rust"
        $ManualSteps += "Install Rust: https://rustup.rs/ (download rustup-init.exe)"
    }
}

# ──────────────────────────────────────────────
# 4. uv (Python package manager)
# ──────────────────────────────────────────────
Write-Info "Checking uv..."
if (Test-Command "uv") {
    $uvVer = uv --version 2>&1
    Write-Ok "uv already installed: $uvVer"
    $AlreadyPresent += "uv"
} else {
    Write-Info "Installing uv..."
    $uvDone = $false

    # Official PowerShell installer
    try {
        irm https://astral.sh/uv/install.ps1 | iex
        if (Test-Command "uv") {
            $uvVer = uv --version 2>&1
            Write-Ok "uv installed: $uvVer"
            $Installed += "uv"
            $uvDone = $true
        }
    } catch {
        # Try winget fallback
        if ($PkgMgr -eq "winget") {
            winget install --silent --accept-package-agreements astral-sh.uv
            if ($LASTEXITCODE -eq 0) { Write-Ok "uv installed via winget"; $Installed += "uv"; $uvDone = $true }
        }
    }

    if (-not $uvDone) {
        Write-Fail "uv installation failed"
        $Failed += "uv"
        $ManualSteps += "Install uv: powershell -c 'irm https://astral.sh/uv/install.ps1 | iex'"
    }
}

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
Write-Host ""
Write-Host ("=" * 44)
Write-Host "  Installation Summary  ($OS / $Arch)"
Write-Host ("=" * 44)

if ($AlreadyPresent.Count -gt 0) {
    Write-Host "Already present:" -ForegroundColor Green
    foreach ($item in $AlreadyPresent) { Write-Host "  - $item" }
}

if ($Installed.Count -gt 0) {
    Write-Host "Newly installed:" -ForegroundColor Green
    foreach ($item in $Installed) { Write-Host "  - $item" }
}

if ($Failed.Count -gt 0) {
    Write-Host "Failed:" -ForegroundColor Red
    foreach ($item in $Failed) { Write-Host "  - $item" }
}

if ($ManualSteps.Count -gt 0) {
    Write-Host ""
    Write-Host "Manual steps required:" -ForegroundColor Yellow
    foreach ($step in $ManualSteps) { Write-Host "  - $step" }
}

Write-Host ("=" * 44)

if ($Failed.Count -gt 0) { exit 1 }
exit 0
