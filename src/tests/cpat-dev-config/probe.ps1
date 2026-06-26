# Smoke-test probe for the cpat-dev-config user-experience flow.
#
# After the master config has been applied, the apps module installs
# git and TortoiseGit via winget. This probe checks both signals:
# `git --version` exits 0 and TortoiseGit appears in uninstall
# registry entries. If either check fails, something likely tripped
# during install and the user should inspect the install transcript.
#
# Output: `OK` if git is on PATH and healthy, and TortoiseGit is
#         discoverable via uninstall metadata; throw otherwise.
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

Write-Output 'OK'
