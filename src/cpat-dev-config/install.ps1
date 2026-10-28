<#
.SYNOPSIS
  Applies CPaT additions after the Microsoft Windows Dev Config baseline.

.DESCRIPTION
  Run setup-baseline.ps1 first and let Microsoft setup finish, including its
  reboot/resume. This launcher only applies the company overlay.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Test-CPaTAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-CPaTDevConfig {
    param([string] $ConfigRoot = $PSScriptRoot)

    if (-not (Test-CPaTAdministrator)) {
        $shell = Join-Path $PSHOME $(if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' })
        $installer = Join-Path $ConfigRoot 'install.ps1'
        $process = Start-Process -FilePath $shell -ArgumentList @('-NoProfile', '-File', "`"$installer`"") -Verb RunAs -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "CPaT Dev Config exited with code $($process.ExitCode)."
        }
        return
    }

    $resume = Get-ScheduledTask -TaskName 'WindowsDevConfigResume' -ErrorAction SilentlyContinue
    if ($resume) {
        throw 'Microsoft setup has a pending reboot/resume. Let it finish before running the CPaT overlay.'
    }

    $common = Join-Path $ConfigRoot '..\Workloads\_common'
    & (Join-Path $common 'refresh-path.ps1')
    foreach ($command in @('git', 'code', 'dotnet', 'npm', 'pwsh')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "Baseline tool '$command' was not found. Run cpat-dev-config\setup-baseline.ps1 and let Microsoft setup finish first."
        }
    }

    Write-Host 'Applying CPaT-only additions to the Microsoft baseline.' -ForegroundColor Cyan
    & (Join-Path $common 'apply-configuration.ps1') `
        -Id 'cpat-dev-config' `
        -ConfigFile (Join-Path $ConfigRoot 'dev-config.winget') `
        -RequireCommands @('git')
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-CPaTDevConfig
    exit 0
}
