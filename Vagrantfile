# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.guest    = :windows
  config.vm.hostname = "sodiusalm"

  #config.ssh.username                  = "vagrant"
  #config.ssh.password                  = "vagrant"

  #See http://docs.vagrantup.com/v2/networking/index.html
  # Port forward WinRM and RDP
  config.vm.communicator = "winrm"
  config.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct:true
  config.vm.network :forwarded_port, guest: 5985, host: 5985, id: "winrm", auto_correct:true

  # Share any additional folders to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  
  # config.vm.synced_folder "../data", "/vagrant_data"

  config.vm.define "sl-win-jazz" do |cci|
      
   #See http://docs.vagrantup.com/v2/vagrantfile/index.html
    cci.vm.box                        = "ju2wheels/SL_WIN_LATEST_64"

    cci.vm.usable_port_range          = 2200..6000

    #See http://docs.vagrantup.com/v2/vagrantfile/ssh_settings.html
    cci.ssh.forward_agent             = true
    cci.ssh.forward_x11               = false
    cci.ssh.private_key_path          = [ File.expand_path("~/.vagrant.d/insecure_private_key") ]

    #See http://docs.vagrantup.com/v2/synced-folders/basic_usage.html

    cci.vm.provider :softlayer do |sl, cci_override|

      sl.api_key                   = ENV["SL_API_KEY"]
      sl.ssh_keys                  = [ "SL-root-pk" ]
      sl.username                  = ENV["SL_API_USERNAME"] || ENV['USER'] || ENV['USERNAME']
      sl.domain                    = ENV["SL_DOMAIN"]
      
      sl.hostname                  = config.vm.hostname
      sl.datacenter                = 'dal05'
      sl.local_disk                = true
      
      sl.network_speed             = 100
      
      sl.post_install              = "https://raw.githubusercontent.com/lonniev/softlayer-windows-jazzclm/master/post_install/windows/bootstrapit.bat"

      #sl.hourly_billing            = true
      #sl.dedicated                 = false
      #sl.disk_capacity             = { 0 => 25 }
      #sl.endpoint_url              = SoftLayer::API_PUBLIC_ENDPOINT
      #sl.force_private_ip          = false
      #sl.manage_dns                = false
      #sl.max_memory                = 1024
      #sl.post_install              = nil #URL for post install script
      #sl.private_only              = false
      #sl.start_cpus                = 1
      #sl.user_data                 = nil
      #sl.vlan_private              = nil
      #sl.vlan_public               = nil

   end if Vagrant.has_plugin?("SoftLayer")
    
   #Windows specific config options for vagrant-windows plugin
   cci.windows.set_work_network      = true
   cci.winrm.port                    = 5985
   cci.winrm.guest_port              = 5985
   cci.winrm.username                = "vagrant"
   cci.winrm.password                = "vagrant"

   #cci.windows.halt_check_interval   = 1
   #cci.windows.halt_timeout          = 30
   #cci.winrm.host                    = "localhost"
   #cci.winrm.max_tries               = 20
   #cci.winrm.timeout                 = 1800
  end

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  #
  config.omnibus.chef_version = :latest
  
  config.vm.provision "chef_solo" do |chef|
    chef.cookbooks_path = "./cookbooks"
    chef.roles_path = "./roles"
    chef.environments_path = "./environments"
    
    chef.add_recipe "windows-jazz"
  end
end
