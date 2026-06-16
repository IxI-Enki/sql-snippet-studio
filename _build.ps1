#!/usr/bin/env pwsh
$pkg = Get-Content (Join-Path $PSScriptRoot "package.json") -Raw | ConvertFrom-Json
$name = $pkg.name
$displayName = $pkg.displayName
$version = $pkg.version

Write-Host "[INFO] Building $displayName v$version"

Write-Host "[INFO] Removing old VSIX files..."
Get-ChildItem -Path $PSScriptRoot -Filter "$name-*.vsix" -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Host "[INFO] Packaging extension..."
Set-Location $PSScriptRoot
vsce package --no-dependencies

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Successfully created VSIX"
    Get-ChildItem -Path $PSScriptRoot -Filter "$name-*.vsix" | Format-List Name, Length, LastWriteTime
} else {
    Write-Host "[ERROR] Failed to create VSIX"
    exit 1
}
