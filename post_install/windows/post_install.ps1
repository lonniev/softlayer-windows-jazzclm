# load any assemblies required
[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")

# Helper Functions
# ----------------
function New-Credential($u,$p) {
    $secpasswd = ConvertTo-SecureString $p -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential ($u, $secpasswd)
}

# configure WinRM
Set-WSManQuickConfig -Force

Set-Item WSMAN:\LocalHost\MaxTimeoutms -Value "1800000"
Set-Item WSMAN:\LocalHost\Client\AllowUnencrypted -Value $true
Set-Item WSMAN:\LocalHost\Client\Auth\Basic -Value $true

Set-Service WinRM -startuptype "automatic"

# make a space for install files
New-Item -ItemType Directory -Force -Path c:\tmp

# obtain an rsync and chmod client for windows
$zipname = "c:\tmp\DeltaCopy.zip"
iwr http://www.aboutmyx.com/files/DeltaCopy.zip -OutFile $zipname
[System.IO.Compression.ZipFile]::ExtractToDirectory( $zipname, "c:\tmp" ) | Out-Host
c:/tmp/setup.exe -S -V-qn | Out-Host
setx PATH "$env:path;c:\DeltaCopy" -m

# create the vagrant user with password vagrant
$userName = "vagrant"
$userHome = "c:\Users\" + $userName
net user $userName $userName /add /expires:never /comment:"Vagrant User"

# add the user created to be added to the local administrators group.
net localgroup Administrators /add $userName

# run a process as the vagrant user to force creation of the user home and profile paths
# -----------
$cred = New-Credential $userName $userName
(Start-Process whoami.exe -Credential $cred)

# obtain a sshd server for windows
iwr http://dl.bitvise.com/BvSshServer-Inst.exe -OutFile c:\tmp\BvSshServer-Inst.exe
C:\tmp\BvSshServer-Inst.exe -acceptEULA -startService -defaultSite | Out-Host

# configure it to sync with users' authorized_keys files
$cmds = @'
access.authKeysSync true
commit
'@
$cmds | C:\"Program Files"\"Bitvise SSH Server"\BssCfg.exe settings importText -i | Out-Host

# copy the vagrant public key to this vagrant user
$vssh=$userHome + "\.ssh"
New-Item -ItemType Directory -Force -Path $vssh
chmod -v 'a-rwx,u+rwx' $vssh
iwr https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -OutFile $vssh\authorized_keys | Out-Host
chmod -v 'a-rwx,u+rw' $vssh\authorized_keys

# schedule a restart of the instance
shutdown /r /t 30 /c "server reboot to complete vagrant post_install" /d p:2:4
