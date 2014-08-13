# obtain a sshd server for windows
md c:\tmp
iwr http://mobassh.mobatek.net/MobaSSH_Server_Home_1.50.zip -OutFile c:\tmp\MobaSSH.zip

# load the assembly required
[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")

$zipname = "c:\tmp\MobaSSH.zip"
[System.IO.Compression.ZipFile]::ExtractToDirectory( $zipname, "c:\tmp" ) | Out-Host

# painfully drive the gui
iwr http://wasp.codeplex.com/downloads/get/55849 -OutFile c:\tmp\WASP.zip

[System.IO.Compression.ZipFile]::ExtractToDirectory( "c:\tmp\WASP.zip", "c:\tmp")
Import-Module c:\tmp\WASP

C:\tmp\MobaSSH_Server_Home_1.50.exe | Out-Host

Select-Window -Title "MobaSSH Installer" | Send-Keys "{ENTER}"
Select-Window -Title "MobaSSH Installer" | Select-ChildWindow | Select-Control -title "Next" | Send-Click
Select-Window -Title "MobaSSH Installer" | Select-ChildWindow | Select-Control -title "No" | Send-Click
Select-Window -Title "MobaSSH Installer" | Remove-Window


# get a reference to the local OS configurator
$computer = [ADSI]"WinNT://localhost"

# create the vagrant user with password vagrant
$userName = "vagrant"
$userHome = "c:\users\" + $userName
md $userHome
$user = $computer.Create("User",$userName )
$user.setpassword( $userName )
$user.put("description", "Vagrant User")
$user.SetInfo()

# ADS_UF_DONT_EXPIRE_PASSWD flag is 0x10000
$user.UserFlags[0] = $user.UserFlags[0] -bor 0x10000
$user.SetInfo()

# add the users created to be added to the local administrators group.
net localgroup Administrators /add $userName

# copy the vagrant public key to this vagrant user
$vssh=$userHome + "\.ssh"
md $vssh\authorized_keys
iwr https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -OutFile $vssh\authorized_keys\vagrant.pub

# configure WinRM
Set-WSManQuickConfig -Force

Set-Item WSMAN:\LocalHost\MaxTimeoutms -Value "1800000"
Set-Item WSMAN:\LocalHost\Client\AllowUnencrypted -Value $true
Set-Item WSMAN:\LocalHost\Client\Auth\Basic -Value $true

Set-Service WinRM -startuptype "automatic"

# schedule a restart of the instance
#shutdown /r /t 10 /c "server reboot to complete vagrant post_install" /d p:2:4
