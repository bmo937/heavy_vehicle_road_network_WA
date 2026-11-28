$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("roads-local-checks-" + [guid]::NewGuid())
$originalPath = $env:PATH
$environmentNames = @("CHECKS_LOG", "CHECKS_FORMATTED", "CHECKS_FORMAT_EXIT", "CHECKS_ANALYZE_EXIT")
$originalEnvironment = @{}
foreach ($name in $environmentNames) {
    $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-Fixture {
    param([string]$Script, [string[]]$Arguments)
    Remove-Item -LiteralPath $env:CHECKS_LOG, $env:CHECKS_FORMATTED -ErrorAction SilentlyContinue
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixtureRoot "tool\$Script") @Arguments 2>&1
    $code = $LASTEXITCODE
    $log = if (Test-Path -LiteralPath $env:CHECKS_LOG) {
        Get-Content -LiteralPath $env:CHECKS_LOG -Raw
    } else {
        ""
    }
    return @{ Code = $code; Output = ($output -join "`n"); Log = $log }
}

try {
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot "tool"), (Join-Path $fixtureRoot "bin") | Out-Null
    Copy-Item -LiteralPath (Join-Path $repositoryRoot "tool\local_checks.ps1"), (Join-Path $repositoryRoot "tool\local_review.ps1") -Destination (Join-Path $fixtureRoot "tool")
    $env:CHECKS_LOG = Join-Path $fixtureRoot "commands.log"
    $env:CHECKS_FORMATTED = Join-Path $fixtureRoot "formatted"
    $env:CHECKS_FORMAT_EXIT = "0"
    $env:CHECKS_ANALYZE_EXIT = "0"
    $env:PATH = (Join-Path $fixtureRoot "bin") + ";" + $env:PATH

    Set-Content -LiteralPath (Join-Path $fixtureRoot "bin\dart.cmd") -Encoding ASCII -Value @'
@echo off
echo dart %*>>"%CHECKS_LOG%"
if not "%CHECKS_FORMAT_EXIT%"=="0" exit /b %CHECKS_FORMAT_EXIT%
echo %*| findstr /L /C:"--output=none" >nul
if not errorlevel 1 (
    if exist "%CHECKS_FORMATTED%" exit /b 0
    echo Changed fixture.dart
    exit /b 1
)
type nul > "%CHECKS_FORMATTED%"
exit /b 0
'@
    Set-Content -LiteralPath (Join-Path $fixtureRoot "bin\flutter.cmd") -Encoding ASCII -Value @'
@echo off
echo flutter %*>>"%CHECKS_LOG%"
if "%~1"=="analyze" exit /b %CHECKS_ANALYZE_EXIT%
exit /b 0
'@
    Set-Content -LiteralPath (Join-Path $fixtureRoot "bin\git.cmd") -Encoding ASCII -Value @'
@echo off
echo git %*>>"%CHECKS_LOG%"
exit /b 0
'@

    $result = Invoke-Fixture "local_checks.ps1" @("-Mode", "Commit")
    Assert-True ($result.Code -eq 1) "Default check must reject unformatted files. Exit: $($result.Code). Output: $($result.Output). Commands: $($result.Log)"
    Assert-True ($result.Output.Contains("-FixFormat")) "Format failure must explain how to fix it."
    Assert-True (-not (Test-Path -LiteralPath $env:CHECKS_FORMATTED)) "Default check must not format files."
    Assert-True (-not $result.Log.Contains("flutter")) "Checks must stop after a formatting failure."

    $result = Invoke-Fixture "local_checks.ps1" @("-Mode", "Commit", "-FixFormat")
    Assert-True ($result.Code -eq 0) "Explicit formatting must unblock commit checks."
    Assert-True ($result.Log.Contains("dart format .")) "FixFormat must write formatting."
    Assert-True ($result.Log.Contains("dart format --output=none --set-exit-if-changed .")) "FixFormat must verify formatting afterwards."
    Assert-True ($result.Log.Contains("flutter analyze")) "Commit checks must still run analysis."
    Assert-True (-not $result.Log.Contains("flutter test")) "Commit checks must not run the full test suite."
    Assert-True (-not $result.Log.Contains("git add")) "Formatting must not stage changes."

    $result = Invoke-Fixture "local_review.ps1" @("-FixFormat")
    Assert-True ($result.Code -eq 0) "Review must forward FixFormat."
    Assert-True ($result.Log.Contains("flutter test")) "Review must still run tests."
    Assert-True ($result.Log.Contains("git diff --check origin/main...HEAD")) "Review must still check the committed diff."
    Assert-True (-not $result.Log.Contains("git add")) "Review must not stage changes."

    $env:CHECKS_FORMAT_EXIT = "2"
    $result = Invoke-Fixture "local_checks.ps1" @("-Mode", "Commit", "-FixFormat")
    Assert-True ($result.Code -eq 1) "Formatter errors must fail validation."
    Assert-True (-not $result.Log.Contains("flutter")) "Formatter errors must stop subsequent checks."

    $env:CHECKS_FORMAT_EXIT = "0"
    $env:CHECKS_ANALYZE_EXIT = "1"
    $result = Invoke-Fixture "local_review.ps1" @("-FixFormat")
    Assert-True ($result.Code -eq 1) "Review must propagate analysis failures."
    Assert-True (-not $result.Log.Contains("flutter test")) "Analysis failures must stop tests."
    Write-Host "PASS: local checks script tests"
}
finally {
    $env:PATH = $originalPath
    foreach ($name in $environmentNames) {
        [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name])
    }
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
