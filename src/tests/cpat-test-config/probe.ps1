# Smoke-test probe for the cpat-test-config user-experience flow.
#
# After the master config has been applied, the apps module installs
# git, TortoiseGit, and Playwright tooling. This probe checks all
# signals: `git --version` exits 0, TortoiseGit appears in uninstall
# registry entries, Playwright CLI resolves, and a Chromium browser
# payload exists under the Playwright browser cache.
#
# Output: `OK` if git is on PATH and healthy, TortoiseGit is
#         discoverable via uninstall metadata, and Playwright
#         Chromium is installed; throw otherwise.
#
# Why a script file (and not an inline run command in manifest.yml):
# the inline form is fine for this particular probe, but `tests/<id>/`
# probe scripts give us room to grow -- for example, asserting that a
# specific registry value matches an expected state -- without
# touching the manifest.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$null = Get-Command git -ErrorAction Stop
$null = & git --version
if ($LASTEXITCODE -ne 0) {
    throw "git --version exited with code $LASTEXITCODE"
}

$uninstallRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$tortoiseGitInstalled = $false
foreach ($root in $uninstallRoots) {
    $match = Get-ItemProperty -Path $root -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like 'TortoiseGit*' } |
        Select-Object -First 1
    if ($null -ne $match) {
        $tortoiseGitInstalled = $true
        break
    }
}

if (-not $tortoiseGitInstalled) {
    throw 'TortoiseGit was not found in uninstall registry entries'
}

$playwrightCmd = Get-Command playwright -ErrorAction SilentlyContinue
if (-not $playwrightCmd) {
    $candidate = Join-Path $env:APPDATA 'npm\playwright.cmd'
    if (Test-Path $candidate) {
        $playwrightCmd = Get-Item -LiteralPath $candidate
    }
}

if (-not $playwrightCmd) {
    throw 'Playwright CLI was not found on PATH or in %APPDATA%\npm'
}

$browserRoot = Join-Path $env:LOCALAPPDATA 'ms-playwright'
$hasChromium = [bool](Get-ChildItem -Path $browserRoot -Directory -Filter 'chromium-*' -ErrorAction SilentlyContinue | Select-Object -First 1)
if (-not $hasChromium) {
    throw 'Playwright Chromium browser was not found under %LOCALAPPDATA%\ms-playwright'
}

Write-Output 'OK'
