# configure WinRM
Set-WSManQuickConfig -Force

Set-Item WSMAN:\LocalHost\MaxTimeoutms -Value "1800000"
Set-Item WSMAN:\LocalHost\Client\AllowUnencrypted -Value $true
Set-Item WSMAN:\LocalHost\Client\Auth\Basic -Value $true

Set-Service WinRM -startuptype "automatic"

# get a reference to the local OS configurator
$computer = [ADSI]"WinNT://localhost"

# create the vagrant user with password vagrant
$userName = "vagrant"
$userHome = "c:\users\" + $userName
md $userHome
$user = $computer.Create("User", $userName )
$user.setpassword( $userName )
$user.put("description", "Vagrant User")
$user.SetInfo()

# ADS_UF_DONT_EXPIRE_PASSWD flag is 0x10000
$user.UserFlags[0] = $user.UserFlags[0] -bor 0x10000
$user.SetInfo()

# add the user created to be added to the local administrators group.
net localgroup Administrators /add $userName

# obtain a sshd server for windows
md c:\tmp
iwr http://dl.bitvise.com/BvSshServer-Inst.exe -OutFile c:\tmp\BvSshServer-Inst.exe
C:\tmp\BvSshServer-Inst.exe -acceptEULA -startService -defaultSite | Out-Host

# configure it to sync with users' authorized_keys files
$cmds = @'
access.authKeysSync true
commit
'@
$cmds | C:\"Program Files"\"Bitvise SSH Server"\BssCfg.exe settings importText -i | Out-Host

# obtain an rsync and chmod client for windows
# load the assembly required
[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")

$zipname = "c:\tmp\DeltaCopy.zip"
iwr http://www.aboutmyx.com/files/DeltaCopy.zip -OutFile $zipname
[System.IO.Compression.ZipFile]::ExtractToDirectory( $zipname, "c:\tmp" ) | Out-Host
c:/tmp/setup.exe /S /v/qn | Out-Host
setx PATH "$env:path;c:\DeltaCopy" -m

# copy the vagrant public key to this vagrant user
$vssh=$userHome + "\.ssh"
md $vssh\authorized_keys
iwr https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -OutFile $vssh\authorized_keys\vagrant

# schedule a restart of the instance
shutdown /r /t 10 /c "server reboot to complete vagrant post_install" /d p:2:4
