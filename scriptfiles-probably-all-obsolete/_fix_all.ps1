#!/usr/bin/env pwsh
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Fixing ALL documentation files..." -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$files = @(
    "README.md",
    "SETUP_GUIDE.md",
    "QUICKSTART.md",
    "NEXT_STEPS.md",
    "LLM_FEATURE.md",
    "PROJECT_CONTEXT.md"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Fixing $file..." -ForegroundColor Yellow
        
        $content = Get-Content $file -Raw -Encoding UTF8
        
        # Fix version references
        $content = $content -replace 'dbi-test-survival-kit-1\.0\.0\.vsix', 'dbi-test-survival-kit-1.1.2.vsix'
        $content = $content -replace 'dbi-test-survival-kit-1\.1\.0\.vsix', 'dbi-test-survival-kit-1.1.2.vsix'
        $content = $content -replace 'dbi-test-survival-kit-1\.1\.1\.vsix', 'dbi-test-survival-kit-1.1.2.vsix'
        
        # Fix old shortcuts
        $content = $content -replace 'Ctrl\+Shift\+S', 'Ctrl+Alt+Shift+S'
        $content = $content -replace 'Ctrl\+Shift\+D', 'Ctrl+Alt+Shift+D'
        $content = $content -replace 'Ctrl\+Shift\+F', 'Ctrl+Alt+Shift+F'
        
        # Fix "Kollegen" to "colleagues" (case variations)
        $content = $content -replace 'Kollegen', 'colleagues'
        $content = $content -replace 'kollegen', 'colleagues'
        
        # Fix German phrases
        $content = $content -replace 'für colleagues', 'for colleagues'
        $content = $content -replace 'Mit colleagues', 'With colleagues'
        $content = $content -replace 'können colleagues', 'colleagues can'
        
        Set-Content $file -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  ✓ Fixed $file" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "SUCCESS: All files fixed!" -ForegroundColor Green

