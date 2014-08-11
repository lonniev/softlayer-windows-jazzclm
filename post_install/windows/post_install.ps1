# get a reference to the local OS configurator
$computer = [ADSI]"WinNT://localhost"

# create the vagrant user with password vagrant
$user = $computer.Create("User","vagrant")
$user.setpassword("vagrant")
$user.put("description", "Vagrant User")
$user.put("HomeDirectory", "c:\users\vagrant")
$user.SetInfo()

# ADS_UF_DONT_EXPIRE_PASSWD flag is 0x10000
$user.UserFlags[0] = $user.UserFlags[0] -bor 0x10000
$user.SetInfo()

# add the users created to be added to the local administrators group.
net localgroup Administrators /add "vagrant"

# configure WinRM
winrm quickconfig

Set-Item WSMAN:\LocalHost\MaxTimeoutms -Value "1800000"
Set-Item WSMAN:\LocalHost\Client\AllowUnencrypted -Value $true
Set-Item WSMAN:\LocalHost\Client\Auth\Basic -Value $true

Set-Service WinRM -startuptype "automatic"
Start-Service WinRM

# obtain a sshd server for windows
md c:\tmp
iwr http://dl.bitvise.com/BvSshServer-Inst.exe -OutFile c:\tmp\BvSshServer-Inst.exe
C:\tmp\BvSshServer-Inst.exe -acceptEULA -startService -defaultSite

# obtain an rsync and chmod client for windows
$zipname = "c:\tmp\DeltaCopy.zip"
$app = new-object -com shell.application
pushd c:\tmp
iwr http://www.aboutmyx.com/files/DeltaCopy.zip -OutFile $zipname
$dest = $app.namespace("c:\tmp")
$zip = $app.namespace($zipname)
$dest.CopyHere($zip.items())
./setup.exe /S /v/qn
setx PATH "$env:path;c:\DeltaCopy" -m
popd

# copy the vagrant public key to this vagrant user
$vssh="c:\Users\vagrant\.ssh"
md $vssh\authorized_keys
c:\DeltaCopy\chmod 700 $vssh
iwr https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -OutFile $vssh\authorized_keys\vagrant.pub
c:\DeltaCopy\chmod 0600 $vssh\authorized_keys

$owner = new-object system.security.principal.ntaccount("vagrant")
get-childitem -literalpath $vssh -force -recurse | Get-Acl | foreach-object { $_.setOwner($owner) }

