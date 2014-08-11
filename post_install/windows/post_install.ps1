# get a reference to the local OS configurator
$computer = [ADSI]"WinNT://."

# create the vagrant user with password vagrant
$user = $computer.Create("User","vagrant")
$user.setpassword("vagrant")
$user.put("Fullname", "Vagrant User")
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
