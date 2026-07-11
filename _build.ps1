#!/usr/bin/env pwsh
$pkg = Get-Content (Join-Path $PSScriptRoot "package.json") -Raw | ConvertFrom-Json
$name = $pkg.name
$version = $pkg.version
$displayName = $pkg.displayName
$outputDir = Join-Path $PSScriptRoot "current_version"
$outputFile = Join-Path $outputDir "$name-$version.vsix"

Write-Host "[INFO] Building $displayName v$version"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "[INFO] Removing old current_version VSIX files..."
Get-ChildItem -Path $outputDir -Filter "$name-*.vsix" -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Host "[INFO] Packaging extension..."
Set-Location $PSScriptRoot
npx @vscode/vsce package --no-dependencies --out $outputFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Successfully created VSIX"
    Get-Item $outputFile | Format-List Name, Length, LastWriteTime
} else {
    Write-Host "[ERROR] Failed to create VSIX"
    exit 1
}
