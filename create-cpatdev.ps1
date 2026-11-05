$username = "cpatdev"
$password = Read-Host "Enter password for $username" -AsSecureString

New-LocalUser `
    -Name $username `
    -Password $password `
    -FullName "CPaT Developer" `
    -Description "CPaT Development Account" `
    -PasswordNeverExpires

Add-LocalGroupMember `
    -Group "Administrators" `
    -Member $username

Write-Host "Created $username and added it to the local Administrators group."