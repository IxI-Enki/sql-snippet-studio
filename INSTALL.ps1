#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick installer for DBI Test Survival Kit extension

.DESCRIPTION
    Installs the extension to VS Code or Cursor by copying files
    to the extensions directory. No npm or vsce required!

.PARAMETER Target
    Target IDE: 'vscode' or 'cursor' (default: both)

.EXAMPLE
    .\INSTALL.ps1

.EXAMPLE
    .\INSTALL.ps1 -Target cursor

.NOTES
    Requires VS Code or Cursor installed
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('vscode', 'cursor', 'both')]
    [string]$Target = 'both'
)

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DBI Test Survival Kit - Quick Installer" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$extensionName = "dbi-test-survival-kit"

# Define extension directories
$vscodeExtDir = "$env:USERPROFILE\.vscode\extensions\$extensionName"
$cursorExtDir = "$env:USERPROFILE\.cursor\extensions\$extensionName"

function Copy-Extension {
    param (
        [string]$TargetDir,
        [string]$IDE
    )
    
    try {
        Write-Host "📦 Installing to $IDE..." -ForegroundColor Yellow
        
        # Create target directory
        if (Test-Path $TargetDir) {
            Write-Host "   ⚠️  Extension already exists, removing old version..." -ForegroundColor DarkYellow
            Remove-Item -Path $TargetDir -Recurse -Force
        }
        
        New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
        
        # Copy files
        $filesToCopy = @(
            'package.json',
            'language-configuration.json',
            'README.md',
            'LICENSE'
        )
        
        foreach ($file in $filesToCopy) {
            $sourcePath = Join-Path $scriptDir $file
            if (Test-Path $sourcePath) {
                Copy-Item -Path $sourcePath -Destination $TargetDir -Force
                Write-Host "   ✓ Copied $file" -ForegroundColor Green
            }
        }
        
        # Copy directories
        $dirsToCopy = @('snippets', 'src', 'images')
        foreach ($dir in $dirsToCopy) {
            $sourcePath = Join-Path $scriptDir $dir
            if (Test-Path $sourcePath) {
                $targetPath = Join-Path $TargetDir $dir
                Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
                $fileCount = (Get-ChildItem -Path $sourcePath -Recurse -File).Count
                Write-Host "   ✓ Copied $dir\ ($fileCount files)" -ForegroundColor Green
            }
        }
        
        Write-Host "   ✅ Successfully installed to $IDE!" -ForegroundColor Green
        Write-Host ""
        return $true
        
    } catch {
        Write-Host "   ❌ Error installing to $IDE : $_" -ForegroundColor Red
        return $false
    }
}

# Install based on target
$installed = $false

if ($Target -eq 'vscode' -or $Target -eq 'both') {
    $vscodePath = Get-Command code -ErrorAction SilentlyContinue
    if ($vscodePath) {
        if (Copy-Extension -TargetDir $vscodeExtDir -IDE "VS Code") {
            $installed = $true
        }
    } else {
        Write-Host "ℹ️  VS Code not found in PATH" -ForegroundColor DarkYellow
    }
}

if ($Target -eq 'cursor' -or $Target -eq 'both') {
    $cursorPath = Get-Command cursor -ErrorAction SilentlyContinue
    if ($cursorPath -or (Test-Path "$env:LOCALAPPDATA\Programs\Cursor")) {
        if (Copy-Extension -TargetDir $cursorExtDir -IDE "Cursor") {
            $installed = $true
        }
    } else {
        Write-Host "ℹ️  Cursor not found" -ForegroundColor DarkYellow
    }
}

if ($installed) {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  ✅ Installation Complete!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📝 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Reload your IDE: Ctrl+Shift+P → 'Reload Window'" -ForegroundColor White
    Write-Host "   2. Open a .sql file" -ForegroundColor White
    Write-Host "   3. Type 'star-schema' and press Tab" -ForegroundColor White
    Write-Host ""
    Write-Host "📚 Documentation:" -ForegroundColor Yellow
    Write-Host "   - README.md - Full documentation" -ForegroundColor White
    Write-Host "   - SETUP_GUIDE.md - Setup & troubleshooting" -ForegroundColor White
    Write-Host ""
    Write-Host "🎉 Happy coding! May your schemas be star-shaped! ⭐" -ForegroundColor Magenta
    
} else {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  ❌ Installation Failed" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "   - VS Code or Cursor is installed" -ForegroundColor White
    Write-Host "   - You have write permissions" -ForegroundColor White
    Write-Host "   - Try running as Administrator" -ForegroundColor White
    Write-Host ""
    Write-Host "For help, see SETUP_GUIDE.md" -ForegroundColor White
    exit 1
}
