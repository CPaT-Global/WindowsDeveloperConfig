<#
.SYNOPSIS
  Launches a CPaT workstation configuration.

.DESCRIPTION
  Prompts for the development or QA workstation profile when -Profile is not
  supplied, then invokes the corresponding configuration shim. Development
  applies CPaT additions after setup-baseline.ps1 has finished; QA is standalone.
#>

[CmdletBinding()]
param(
    [ValidateSet('Dev', 'QA')]
    [string]$Profile
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $Profile) {
    do {
        Write-Host 'Select a CPaT workstation configuration:'
        Write-Host '  1. Development additions (run Microsoft baseline first; Docker Desktop, ABP Studio)'
        Write-Host '  2. QA (Playwright-focused; no Docker Desktop or WSL)'
        $selection = Read-Host 'Enter 1 or 2'

        $Profile = switch ($selection) {
            '1' { 'Dev' }
            '2' { 'QA' }
            default { $null }
        }

        if (-not $Profile) {
            Write-Warning 'Enter 1 for the development configuration or 2 for the QA configuration.'
        }
    } while (-not $Profile)
}

$configName = if ($Profile -eq 'Dev') { 'cpat-dev-config' } else { 'cpat-test-config' }
$installer = Join-Path $PSScriptRoot "$configName\install.ps1"

if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) {
    throw "Configuration launcher was not found: $installer"
}

Write-Host "Starting $configName..." -ForegroundColor Cyan
if ($Profile -eq 'Dev') {
    Write-Host 'Prerequisite: run .\cpat-dev-config\setup-baseline.ps1 and let Microsoft setup finish first.'
}
& $installer

if ($LASTEXITCODE -ne 0) {
    throw "$configName failed with exit code $LASTEXITCODE."
}
