<#
.SYNOPSIS
  Launches a CPaT workstation configuration.

.DESCRIPTION
  Prompts for the development or QA workstation profile when -Profile is not
  supplied, then invokes the corresponding configuration shim.
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
        Write-Host '  1. Development (Docker Desktop, ABP Studio, WSL + Ubuntu; may reboot)'
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
& $installer

if ($LASTEXITCODE -ne 0) {
    throw "$configName failed with exit code $LASTEXITCODE."
}
