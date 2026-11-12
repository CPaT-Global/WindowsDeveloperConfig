<#
.SYNOPSIS
  Runs the pinned, Microsoft-signed Windows Dev Config Full setup.

.DESCRIPTION
  Let this setup finish, including its reboot/resume, before running install.ps1
  for the CPaT additions. Microsoft scripts and signature checks stay unchanged.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-CPaTMicrosoftBaseline {
    # Match the published payload used by Microsoft's setup-full.ps1.
    $payloadRef = 'fe21c03a486a1076c425720c1ebe4e25404e0e6b'
    $uri = "https://raw.githubusercontent.com/microsoft/WindowsDeveloperConfig/$payloadRef/windows-dev-config/bootstrap.ps1"
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $bootstrap = (Invoke-RestMethod -Uri $uri -UseBasicParsing -TimeoutSec 60).TrimStart([char]0xFEFF)
    $signature = Get-AuthenticodeSignature -Content ([Text.Encoding]::Unicode.GetBytes($bootstrap)) -SourcePathOrExtension '.ps1'
    if ($signature.Status -ne 'Valid' -or -not $signature.SignerCertificate -or
        $signature.SignerCertificate.Subject -ne 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US') {
        throw 'The Microsoft baseline bootstrap failed signature verification. No setup was started.'
    }

    $installRoot = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'CPaT-MicrosoftBaseline'
    & ([scriptblock]::Create($bootstrap)) -Ref $payloadRef -InstallRoot $installRoot -Action Full
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-CPaTMicrosoftBaseline
}
