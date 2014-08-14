Write-Progress -Activity "Vagrant Post Install" -Status "Enabling WinRM..." -PercentComplete 0 -SecondsRemaining 110

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

Set-Service WinRM -startuptype "automatic"

Write-Progress -Activity "Vagrant Post Install" -Status "Downloading and unzipping DeltaCopy..." -PercentComplete 20 -SecondsRemaining 100

# make a space for install files
New-Item -ItemType Directory -Force -Path c:\tmp

# obtain an rsync and chmod client for windows
Invoke-Command -ScriptBlock {
[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
$zipname = "c:\tmp\DeltaCopy.zip"
iwr http://www.aboutmyx.com/files/DeltaCopy.zip -OutFile $zipname
[System.IO.Compression.ZipFile]::ExtractToDirectory( $zipname, "c:\tmp" )

c:/tmp/setup.exe -S -V-qn
setx PATH "$env:path;c:\DeltaCopy" -m
}

# create the vagrant user with password vagrant
Write-Progress -Activity "Vagrant Post Install" -Status "Creating vagrant Administrator..." -PercentComplete 30 -SecondsRemaining 80

$userName = "vagrant"
net user $userName $userName /add /expires:never /comment:"Vagrant User"

# add the user created to be added to the local administrators group.
net localgroup Administrators /add $userName

# run a process as the vagrant user to force creation of the user home and profile paths
# -----------
$cred = New-Credential $userName $userName
Start-Process -Wait -NoNewWindow whoami.exe -Credential $cred

# obtain a sshd server for windows
Write-Progress -Activity "Vagrant Post Install" -Status "Downloading and installing Sshd Server..." -PercentComplete 40 -SecondsRemaining 70

iwr http://dl.bitvise.com/BvSshServer-Inst.exe -OutFile c:\tmp\BvSshServer-Inst.exe
C:\tmp\BvSshServer-Inst.exe -acceptEULA -startService -defaultSite

# configure it to sync with users' authorized_keys files
$cmds = @'
access.authKeysSync true
commit
'@
$cmds | C:\"Program Files"\"Bitvise SSH Server"\BssCfg.exe settings importText -i 

# as the vagrant user, copy the vagrant public key to this vagrant user's authorized keys
Write-Progress -Activity "Vagrant Post Install" -Status "Obtaining vagrant public key..." -PercentComplete 50 -SecondsRemaining 50

Invoke-Command -ScriptBlock {
$vssh="c:\users\vagrant\.ssh"
New-Item -ItemType Directory -Force -Path $vssh
c:\DeltaCopy\chmod -v 'a-rwx,u+rwx' $vssh
iwr https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -OutFile $vssh\authorized_keys
c:\DeltaCopy\chmod -v 'a-rwx,u+rw' $vssh\authorized_keys
} -Credential $cred

# schedule a restart of the instance
Write-Progress -Activity "Vagrant Post Install" -Status "Scheduling restart..." -PercentComplete 80 -SecondsRemaining 40

shutdown -r -t 40 -c "server reboot to complete vagrant post_install." -d p:2:4

Write-Host -ForegroundColor "Done. Bye..."