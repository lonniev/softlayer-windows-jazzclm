Write-Progress -Activity "Vagrant Post Install" -Status "Enabling WinRM..." -PercentComplete 0 -SecondsRemaining 110
Write-Host -ForegroundColor Green "Enabling WinRM..."

# Helper Functions
# ----------------
function New-Credential($u,$p) {
    $secpasswd = ConvertTo-SecureString $p -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential ($u, $secpasswd)
}

# configure WinRM
Set-WSManQuickConfig -Force

Set-Item WSMAN:\LocalHost\MaxTimeoutms -Value "1800000"
Set-Item WSMAN:\LocalHost\Service\AllowUnencrypted -Value $true
Set-Item WSMAN:\LocalHost\Service\Auth\Basic -Value $true
Set-Item WSMAN:\LocalHost\Client\Auth\Basic -Value $true
Set-Item WSMan:\Localhost\Client\TrustedHosts -Value "*" -Force

Set-Service WinRM -startuptype "automatic"

Enable-PSRemoting -force

Write-Progress -Activity "Vagrant Post Install" -Status "Downloading and unzipping DeltaCopy..." -PercentComplete 20 -SecondsRemaining 100
Write-Host -ForegroundColor Green "Downloading and unzipping DeltaCopy..."

# make a space for install files
New-Item -ItemType Directory -Force -Path c:\tmp

# obtain an rsync and chmod client for windows
Invoke-Command -ScriptBlock {
if ( -Not (Test-Path c:\DeltaCopy\rsync.exe) )
{
[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
$zipname = "c:\tmp\DeltaCopy.zip"
iwr http://www.aboutmyx.com/files/DeltaCopy.zip -OutFile $zipname
[System.IO.Compression.ZipFile]::ExtractToDirectory( $zipname, "c:\tmp" )

Write-Host -ForegroundColor Green "Installing and pathing DeltaCopy..."

c:\tmp\setup.exe -S -V-qn
setx PATH "$env:path;c:\DeltaCopy" -m
}
}

$userName = "vagrant"
if ( -Not ( Test-Path "c:\users\vagrant" ) )
{
# create the vagrant user with password vagrant
Write-Progress -Activity "Vagrant Post Install" -Status "Creating vagrant Administrator..." -PercentComplete 30 -SecondsRemaining 80
Write-Host -ForegroundColor Green "Creating vagrant Administrator..."

net user $userName $userName /add /expires:never /comment:"Vagrant User"
}

# add the user created to be added to the local administrators group.
net localgroup Administrators /add $userName

# run a process as the vagrant user to force creation of the user home and profile paths
# -----------
$cred = New-Credential $userName $userName
Start-Process -Wait -NoNewWindow whoami.exe -Credential $cred

# obtain a sshd server for windows
if ( -Not (Test-Path C:\"Program Files"\"Bitvise SSH Server") )
{
Write-Progress -Activity "Vagrant Post Install" -Status "Downloading and installing Sshd Server..." -PercentComplete 40 -SecondsRemaining 70
Write-Host -ForegroundColor Green "Downloading and installing Sshd Server..."

Invoke-Command -ScriptBlock {
iwr http://dl.bitvise.com/BvSshServer-Inst.exe -OutFile c:\tmp\BvSshServer-Inst.exe
C:\tmp\BvSshServer-Inst.exe -acceptEULA -startService -defaultSite
}
}

# configure WinSshd to sync with users' authorized_keys files
$cmds = @'
access.authKeysSync true
commit
'@
$cmds | C:\"Program Files"\"Bitvise SSH Server"\BssCfg.exe settings importText -i 

# as the vagrant user, copy the vagrant public key to this vagrant user's authorized keys
Write-Progress -Activity "Vagrant Post Install" -Status "Obtaining vagrant public key..." -PercentComplete 50 -SecondsRemaining 50
Write-Host -ForegroundColor Green "Obtaining vagrant public key..."

@'
$vssh="c:\users\vagrant\.ssh"
if ( -Not (Test-Path $vssh\authorized_keys) )
{
New-Item -ItemType Directory -Force -Path $vssh
c:\DeltaCopy\chmod -v 'a-rwx,u+rwx' $vssh
iwr https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -OutFile $vssh\authorized_keys
c:\DeltaCopy\chmod -v 'a-rwx,u+rw' $vssh\authorized_keys
Write-Host -ForegroundColor Green "Created $vssh\authorized_keys."
}
'@ | Out-File c:\tmp\get_key.ps1

Start-Process powershell.exe -ArgumentList "-file c:\tmp\get_key.ps1" -Wait -NoNewWindow -Credential $cred

# schedule a restart of the instance
Write-Progress -Activity "Vagrant Post Install" -Status "Scheduling restart..." -PercentComplete 80 -SecondsRemaining 40
Write-Host -ForegroundColor Green "Scheduling restart..."

Start-Sleep 10
Write-Host -ForegroundColor Green "Done. Bye..."
Write-Progress -Activity "Vagrant Post Install" -Status "Scheduling restart..." -PercentComplete 90 -SecondsRemaining 5

#shutdown -r -t 5 -c "server reboot to complete vagrant post_install." -d p:2:4
