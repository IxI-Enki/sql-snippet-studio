#!/usr/bin/env pwsh
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Building VSIX v1.1.0" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Remove old VSIX
Write-Host "Removing old VSIX files..." -ForegroundColor Yellow
Remove-Item "dbi-test-survival-kit-*.vsix" -Force -ErrorAction SilentlyContinue

# Package
Write-Host "Packaging extension..." -ForegroundColor Yellow
vsce package --no-dependencies

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Successfully created VSIX!" -ForegroundColor Green
    Get-ChildItem "dbi-test-survival-kit-*.vsix" | Format-List Name, Length, LastWriteTime
} else {
    Write-Host ""
    Write-Host "❌ Failed to create VSIX!" -ForegroundColor Red
    exit 1
}
