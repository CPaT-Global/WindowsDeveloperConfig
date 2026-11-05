# Reset developer Git credentials for machine handoff
# Run as the CURRENT developer before handing over the machine.

Write-Host "Resetting Git credentials and developer identity..." -ForegroundColor Cyan

# ============================================================
# 1. Remove global Git identity
# ============================================================

git config --global --unset-all user.name  2>$null
git config --global --unset-all user.email 2>$null
git config --global --unset-all github.user 2>$null


# ============================================================
# 2. Clear Git Credential Manager credentials
# ============================================================

if (Get-Command git -ErrorAction SilentlyContinue) {

    # GitHub
    "protocol=https`nhost=github.com`n" | git credential reject

    # Azure DevOps
    "protocol=https`nhost=dev.azure.com`npath=cpat`n" | git credential reject

    # Legacy Azure DevOps / VSTS
    "protocol=https`nhost=visualstudio.com`n" | git credential reject
}


# ============================================================
# 3. Remove Git credentials from Windows Credential Manager
# ============================================================

$credentials = cmdkey /list

$targets = $credentials |
    Select-String "Target:" |
    ForEach-Object {
        ($_ -replace '^\s*Target:\s*', '').Trim()
    } |
    Where-Object {
        $_ -match '(git|github|dev\.azure\.com|visualstudio\.com)'
    }

foreach ($target in $targets) {
    Write-Host "Removing credential: $target"
    cmdkey /delete:$target | Out-Null
}


# ============================================================
# 4. Logout of GitHub CLI
# ============================================================

if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "Logging out of GitHub CLI..."
    gh auth logout --hostname github.com 2>$null
}


# ============================================================
# 5. Remove Azure DevOps CLI cached PAT
# ============================================================

$azDevOpsTokenFile =
    Join-Path $env:USERPROFILE ".azure\azuredevops\personalAccessToken"

if (Test-Path $azDevOpsTokenFile) {
    Write-Host "Removing cached Azure DevOps PAT..."
    Remove-Item $azDevOpsTokenFile -Force
}


# ============================================================
# 6. Remove identities currently loaded into SSH agent
# ============================================================

if (Get-Command ssh-add -ErrorAction SilentlyContinue) {
    Write-Host "Removing identities from SSH agent..."
    ssh-add -D 2>$null
}


# ============================================================
# 7. Safely remove personal SSH keys
#
# Preserve:
#   config
#   known_hosts
#   known_hosts.old
#   authorized_keys
#
# Remove recognized private keys and their matching .pub files.
# ============================================================

$sshPath = Join-Path $env:USERPROFILE ".ssh"

if (Test-Path $sshPath) {

    Write-Host "`nInspecting SSH directory: $sshPath" -ForegroundColor Cyan

    $files = Get-ChildItem $sshPath -File -ErrorAction SilentlyContinue

    $preservedFiles = @(
        "config",
        "known_hosts",
        "known_hosts.old",
        "authorized_keys"
    )

    foreach ($file in $files) {

        if ($file.Name -in $preservedFiles) {
            Write-Host "Preserving SSH configuration: $($file.Name)"
            continue
        }

        # Detect private keys by their contents rather than filename.
        $firstLines = Get-Content $file.FullName -TotalCount 3 `
            -ErrorAction SilentlyContinue

        $isPrivateKey = $firstLines -match `
            "BEGIN (OPENSSH|RSA|DSA|EC|ED25519) PRIVATE KEY"

        if ($isPrivateKey) {

            Write-Host "Removing SSH private key: $($file.Name)" `
                -ForegroundColor Yellow

            # Remove matching public key first.
            $publicKey = "$($file.FullName).pub"

            if (Test-Path $publicKey) {
                Write-Host "Removing matching public key: $($file.Name).pub"
                Remove-Item $publicKey -Force
            }

            # Remove private key.
            Remove-Item $file.FullName -Force
        }
    }
}


# ============================================================
# 8. Display remaining SSH files
# ============================================================

Write-Host "`nRemaining SSH files:" -ForegroundColor Yellow

if (Test-Path $sshPath) {
    Get-ChildItem $sshPath -File |
        Select-Object Name, LastWriteTime
}


# ============================================================
# 9. Display remaining global Git configuration
# ============================================================

Write-Host "`nRemaining global Git configuration:" `
    -ForegroundColor Yellow

git config --global --list


# ============================================================
# Done
# ============================================================

Write-Host "`n========================================" `
    -ForegroundColor Green

Write-Host "Developer Git credentials have been reset." `
    -ForegroundColor Green

Write-Host "========================================`n" `
    -ForegroundColor Green

Write-Host "The next developer should configure:"
Write-Host ""
Write-Host '  git config --global user.name "Their Name"'
Write-Host '  git config --global user.email "their.email@company.com"'
Write-Host ""
Write-Host "They will need to authenticate with GitHub/Azure DevOps"
Write-Host "or create their own SSH key."