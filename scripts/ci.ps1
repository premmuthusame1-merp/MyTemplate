# ci.ps1 — Windows (PowerShell) equivalent of `make ci`.
# Runs the full quality pipeline and writes all artifacts to reports/.
# Usage from the repo root:
#   powershell -ExecutionPolicy Bypass -File scripts/ci.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/ci.ps1 -Step test   # run one step

param(
    [ValidateSet("lint", "security", "test", "ui-test", "ci")]
    [string]$Step = "ci"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Python = Join-Path $RepoRoot "env\Scripts\python.exe"
$Reports = Join-Path $RepoRoot "reports"

if (-not (Test-Path $Python)) {
    Write-Host "Virtual env not found. Run: env\Scripts\python -m venv env" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $Reports | Out-Null

function Run-Step([string]$Name, [string[]]$ArgsList) {
    Write-Host ""
    Write-Host "===== $Name =====" -ForegroundColor Cyan
    $env:APPNAME_ENV = "test"
    & $Python -m pytest $ArgsList
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED: $Name (exit $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

function Step-Lint {
    $env:APPNAME_ENV = ""
    & $Python -m ruff check appname manage.py wsgi.py tests --output-format json --output-file (Join-Path $Reports "ruff.json")
    & $Python -m ruff check appname manage.py wsgi.py tests
}

function Step-Security {
    $env:APPNAME_ENV = ""
    & $Python -m bandit -r appname manage.py wsgi.py -x "appname/static" -f json -o (Join-Path $Reports "bandit.json") -q
}

function Step-Test {
    Run-Step "Unit tests + coverage" @(
        "tests", "--ignore=tests/ui",
        "--cov=appname",
        "--cov-report=term-missing",
        "--cov-report=xml:$Reports\coverage.xml",
        "--cov-report=html:$Reports\html",
        "--junitxml=$Reports\junit.xml"
    )
}

function Step-UiTest {
    Run-Step "Playwright UI tests" @(
        "tests/ui", "--browser=chromium",
        "--output=$Reports\ui",
        "--junitxml=$Reports\ui-junit.xml"
    )
}

switch ($Step) {
    "lint"     { Step-Lint }
    "security" { Step-Security }
    "test"     { Step-Test }
    "ui-test"  { Step-UiTest }
    "ci"       { Step-Lint; Step-Security; Step-Test; Step-UiTest }
}

Write-Host ""
Write-Host "===== Build artifacts in reports/ =====" -ForegroundColor Cyan
Get-ChildItem -Recurse $Reports | Select-Object FullName, Length | Format-Table -AutoSize
Write-Host ""
Write-Host "Quality pipeline completed successfully." -ForegroundColor Green