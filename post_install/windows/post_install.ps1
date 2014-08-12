# get a reference to the local OS configurator
$computer = [ADSI]"WinNT://localhost"

# create the vagrant user with password vagrant
$userName = "vagrant"
$userHome = "c:\users\" + $userName
md $userHome
$user = $computer.Create("User",$userName )
$user.setpassword( $userName )
$user.put("description", "Vagrant User")
$user.put("homedirectory", $userHome)
$user.put("profile", $userHome)
$user.SetInfo()

# ADS_UF_DONT_EXPIRE_PASSWD flag is 0x10000
$user.UserFlags[0] = $user.UserFlags[0] -bor 0x10000
$user.SetInfo()

# add the users created to be added to the local administrators group.
net localgroup Administrators /add $userName

# in unix this would be chown -R vagrant.vagrant /home/vagrant
$account="\\"+$user.Name
$homedir=$user.HomeDirectory
$rights=[System.Security.AccessControl.FileSystemRights]::FullControl
$inheritance=[System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
$propagation=[System.Security.AccessControl.PropagationFlags]::None
$allowdeny=[System.Security.AccessControl.AccessControlType]::Allow

$dirACE=New-Object System.Security.AccessControl.FileSystemAccessRule ($account,$rights,$inheritance,$propagation,$allowdeny)

$dirACL=Get-Acl $homedir

$dirACL.AddAccessRule($dirACE)

Set-Acl $homedir $dirACL

# configure WinRM
Set-WSManQuickConfig -Force

Set-Item WSMAN:\LocalHost\MaxTimeoutms -Value "1800000"
Set-Item WSMAN:\LocalHost\Client\AllowUnencrypted -Value $true
Set-Item WSMAN:\LocalHost\Client\Auth\Basic -Value $true

Set-Service WinRM -startuptype "automatic"

# obtain a sshd server for windows
md c:\tmp
iwr http://dl.bitvise.com/BvSshServer-Inst.exe -OutFile c:\tmp\BvSshServer-Inst.exe
C:\tmp\BvSshServer-Inst.exe -acceptEULA -startService -defaultSite

# obtain an rsync and chmod client for windows
# load the assembly required
[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem"

$zipname = "c:\tmp\DeltaCopy.zip"
iwr http://www.aboutmyx.com/files/DeltaCopy.zip -OutFile $zipname
[System.IO.Compression.ZipFile]::ExtractToDirectory( $zipname, "c:\tmp" )
c:/tmp/setup.exe /S /v/qn
setx PATH "$env:path;c:\DeltaCopy" -m

# copy the vagrant public key to this vagrant user
$vssh=$userHome + "\.ssh"
md $vssh\authorized_keys
c:\DeltaCopy\chmod 700 $vssh
iwr https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -OutFile $vssh\authorized_keys\vagrant.pub
c:\DeltaCopy\chmod 0600 $vssh\authorized_keys

$owner = new-object system.security.principal.ntaccount("vagrant")
get-childitem -literalpath $vssh -force -recurse | Get-Acl | foreach-object { $_.setOwner($owner) }

