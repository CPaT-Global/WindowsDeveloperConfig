$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot '..\_harness\assertions.ps1')
. (Join-Path $PSScriptRoot '..\..\cpat-dev-config\setup-baseline.ps1')
. (Join-Path $PSScriptRoot '..\..\cpat-dev-config\install.ps1')

$script:signatureStatus = 'Valid'
$script:signer = [pscustomobject]@{
    Subject = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
}
$script:downloadFailure = $false
$script:downloadUri = ''
function Invoke-RestMethod {
    param($Uri, [switch] $UseBasicParsing, $TimeoutSec)
    if ($script:downloadFailure) { throw 'Download failed' }
    $script:downloadUri = $Uri
    return @'
param($Ref, $InstallRoot, $Action)
[pscustomobject]@{ Ref = $Ref; InstallRoot = $InstallRoot; Action = $Action }
'@
}
function Get-AuthenticodeSignature {
    param($Content, $SourcePathOrExtension)
    return [pscustomobject]@{ Status = $script:signatureStatus; SignerCertificate = $script:signer }
}

$baseline = Invoke-CPaTMicrosoftBaseline
Assert-True ($script:downloadUri -match '^https://raw\.githubusercontent\.com/microsoft/WindowsDeveloperConfig/([a-f0-9]{40})/windows-dev-config/bootstrap\.ps1$') 'Baseline should use a pinned Microsoft bootstrap'
Assert-Equal $baseline.Ref $Matches[1] 'Bootstrap and payload should use the same pinned revision'
Assert-Equal $baseline.Action 'Full' 'Dev machines should receive the Microsoft Full baseline'
Assert-Equal (Split-Path -Leaf $baseline.InstallRoot) 'CPaT-MicrosoftBaseline' 'Baseline should use an isolated installation directory'

foreach ($status in @('NotSigned', 'HashMismatch')) {
    $script:signatureStatus = $status
    Assert-ThrowsLike { Invoke-CPaTMicrosoftBaseline } '*failed signature verification*' "Reject $status bootstrap content"
}
$script:signatureStatus = 'Valid'
$script:signer.Subject = 'CN=Other Publisher'
Assert-ThrowsLike { Invoke-CPaTMicrosoftBaseline } '*failed signature verification*' 'Reject a different publisher'
$script:signer = $null
Assert-ThrowsLike { Invoke-CPaTMicrosoftBaseline } '*failed signature verification*' 'Reject a missing signing certificate'
$script:downloadFailure = $true
Assert-ThrowsLike { Invoke-CPaTMicrosoftBaseline } '*Download failed*' 'Propagate download failures without starting setup'

$script:elevated = $true
$script:resumePending = $false
$script:missingCommand = ''
$script:elevationExitCode = 0
function Test-CPaTAdministrator { return $script:elevated }
function Get-ScheduledTask {
    [CmdletBinding()]
    param($TaskName)
    if ($script:resumePending) { return [pscustomobject]@{ TaskName = $TaskName } }
}
function Get-Command {
    [CmdletBinding()]
    param([string] $Name)
    if ($Name -ne $script:missingCommand) { return [pscustomobject]@{ Name = $Name } }
}
function Start-Process {
    param($FilePath, $ArgumentList, $Verb, [switch] $Wait, [switch] $PassThru)
    Assert-Equal $Verb 'RunAs' 'Overlay should request UAC elevation'
    Assert-True ([bool]$Wait) 'Launcher should wait for the elevated overlay'
    Assert-True (($ArgumentList -join ' ') -like '*install.ps1*') 'Elevation should rerun only the overlay'
    return [pscustomobject]@{ ExitCode = $script:elevationExitCode }
}

$fixture = Join-Path $env:TEMP "cpat-overlay-$([guid]::NewGuid().ToString('N'))"
try {
    $configRoot = Join-Path $fixture 'cpat-dev-config'
    $common = Join-Path $fixture 'Workloads\_common'
    New-Item -ItemType Directory -Path $configRoot, $common -Force | Out-Null
    $events = Join-Path $common 'events.txt'
    Set-Content -LiteralPath (Join-Path $common 'refresh-path.ps1') -Value @'
Add-Content -LiteralPath (Join-Path $PSScriptRoot 'events.txt') -Value 'refresh'
'@
    Set-Content -LiteralPath (Join-Path $common 'apply-configuration.ps1') -Value @'
param($Id, $ConfigFile, $RequireCommands)
Add-Content -LiteralPath (Join-Path $PSScriptRoot 'events.txt') -Value "overlay:$Id"
if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'fail.txt')) { throw 'Overlay failed' }
"INSTALL_OK: $Id"
'@

    $script:resumePending = $true
    Assert-ThrowsLike { Invoke-CPaTDevConfig -ConfigRoot $configRoot } '*pending reboot/resume*' 'Do not apply the overlay while Microsoft has a pending resume'
    Assert-True (-not (Test-Path -LiteralPath $events)) 'Pending baseline should prevent overlay execution'
    $script:resumePending = $false
    $script:missingCommand = 'npm'
    Assert-ThrowsLike { Invoke-CPaTDevConfig -ConfigRoot $configRoot } "*Baseline tool 'npm' was not found*" 'Reject an incomplete baseline'
    Assert-Equal ((Get-Content -LiteralPath $events) -join ',') 'refresh' 'Missing prerequisites should prevent configuration'

    Remove-Item -LiteralPath $events
    $script:missingCommand = ''
    $output = @(Invoke-CPaTDevConfig -ConfigRoot $configRoot)
    Assert-Equal ((Get-Content -LiteralPath $events) -join ',') 'refresh,overlay:cpat-dev-config' 'Refresh PATH before applying only the CPaT overlay'
    Assert-Equal $output[-1] 'INSTALL_OK: cpat-dev-config' 'Emit success only after the overlay completes'

    Set-Content -LiteralPath (Join-Path $common 'fail.txt') -Value 'fail'
    Assert-ThrowsLike { Invoke-CPaTDevConfig -ConfigRoot $configRoot } '*Overlay failed*' 'Do not hide overlay failures'

    Remove-Item -LiteralPath $events
    $script:elevated = $false
    Invoke-CPaTDevConfig -ConfigRoot $configRoot
    Assert-True (-not (Test-Path -LiteralPath $events)) 'Unelevated parent should not also apply the overlay'
    $script:elevationExitCode = 1
    Assert-ThrowsLike { Invoke-CPaTDevConfig -ConfigRoot $configRoot } '*exited with code 1*' 'Propagate elevated process failure'
} finally {
    Remove-Item -LiteralPath $fixture -Recurse -Force
}

Write-Host "CPAT_UNIT_OK: $script:AssertionCount assertions"
