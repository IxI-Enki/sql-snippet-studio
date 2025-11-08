# ============================================================================
# INSTALLATION SCRIPT - DBI Test Survival Kit v1.6.2
# ============================================================================
# FIX: Critical Cache Bug - Model-Name im Cache-Key
# ============================================================================

Write-Host "=== DBI TEST SURVIVAL KIT v1.6.2 INSTALLATION ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔧 CRITICAL FIX: Cache-Bug beim Model-Wechsel" -ForegroundColor Yellow
Write-Host "   - Cache enthält jetzt Model-Namen im Key" -ForegroundColor Yellow
Write-Host "   - Keine Cache-Kollisionen mehr bei Model-Wechsel" -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# STEP 1: Deinstalliere alte Version
# ============================================================================

Write-Host "Step 1: Deinstalliere alte Version..." -ForegroundColor Cyan

$extensions = code --list-extensions --show-versions | Select-String "dbi-team.dbi-test-survival-kit"

if ($extensions) {
    Write-Host "   Gefunden: $extensions" -ForegroundColor Yellow
    Write-Host "   Deinstalliere..." -ForegroundColor Yellow
    code --uninstall-extension dbi-team.dbi-test-survival-kit | Out-Null
    Start-Sleep -Seconds 2
    Write-Host "   ✅ Alte Version deinstalliert" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Keine alte Version gefunden" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# STEP 2: Installiere neue Version
# ============================================================================

Write-Host "Step 2: Installiere neue Version v1.6.2..." -ForegroundColor Cyan

if (Test-Path "dbi-test-survival-kit-1.6.2.vsix") {
    Write-Host "   VSIX gefunden: dbi-test-survival-kit-1.6.2.vsix" -ForegroundColor Green
    Write-Host "   Installiere..." -ForegroundColor Yellow
    
    code --install-extension dbi-test-survival-kit-1.6.2.vsix --force | Out-Null
    Start-Sleep -Seconds 2
    
    Write-Host "   ✅ v1.6.2 installiert" -ForegroundColor Green
} else {
    Write-Host "   ❌ VSIX nicht gefunden!" -ForegroundColor Red
    Write-Host "   Bitte zuerst 'npm run package' ausführen" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# STEP 3: Verifiziere Installation
# ============================================================================

Write-Host "Step 3: Verifiziere Installation..." -ForegroundColor Cyan

Start-Sleep -Seconds 2
$installed = code --list-extensions --show-versions | Select-String "dbi-team.dbi-test-survival-kit@1.6.2"

if ($installed) {
    Write-Host "   ✅ Installation erfolgreich!" -ForegroundColor Green
    Write-Host "   Version: $installed" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Version konnte nicht verifiziert werden" -ForegroundColor Yellow
    Write-Host "   Bitte Cursor neu starten und manuell prüfen" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# STEP 4: Wichtige Hinweise
# ============================================================================

Write-Host "=== WICHTIGE HINWEISE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔄 BITTE CURSOR NEU STARTEN!" -ForegroundColor Red
Write-Host "   - Schließe ALLE Cursor-Fenster" -ForegroundColor Yellow
Write-Host "   - Warte 5 Sekunden" -ForegroundColor Yellow
Write-Host "   - Öffne Cursor neu" -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ NACH NEUSTART:" -ForegroundColor Green
Write-Host "   1. Prüfe Version in Extensions (sollte 1.6.2 sein)" -ForegroundColor White
Write-Host "   2. Konfiguriere Model in Settings:" -ForegroundColor White
Write-Host "      dbiSurvivalKit.llm.model = 'llama-3-sqlcoder-8b'" -ForegroundColor Cyan
Write-Host "   3. Starte LM Studio mit llama-3-sqlcoder-8b" -ForegroundColor White
Write-Host "   4. Teste mit Ctrl+Alt+Shift+Q" -ForegroundColor White
Write-Host "   5. Prüfe dass LM Studio GENERIERT (nicht aus Cache)" -ForegroundColor White
Write-Host ""
Write-Host "🐛 BUG-FIX DETAILS:" -ForegroundColor Yellow
Write-Host "   Siehe: CACHE_BUG_FIX_v1.6.2.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== INSTALLATION ABGESCHLOSSEN ===" -ForegroundColor Green
Write-Host ""
Write-Host "🤓🤜🏻🤛🏻🤖 BEREIT ZUM TESTEN!" -ForegroundColor Magenta
Write-Host ""
