powershell -command "& {set-executionpolicy -force unrestricted; iwr https://raw.githubusercontent.com/lonniev/softlayer-windows-jazzclm/master/post_install/windows/post_install.ps1 -OutFile post_install.ps1; .\post_install.ps1}"

shutdown /r /t 10 /c "server reboot to complete vagrant post_install" /d p:2:4