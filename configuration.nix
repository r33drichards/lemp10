# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:


{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable =
    true; # Easiest to use and most distros use this by default.
  networking.nameservers = [ "100.100.100.100" "8.8.8.8" ];

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Persisting user passwords 
  # to create the password files, run:
  # $ sudo su
  # $ nix-shell -p mkpasswd
  # $ mkdir -p /persist/passwords
  # $ mkpasswd -m sha-512 > /persist/passwords/root
  # $ mkpasswd -m sha-512 > /persist/passwords/alice
  users.mutableUsers = false;
  fileSystems."/persist".neededForBoot = true;

  users.users.root.passwordFile = "/persist/passwords/root";
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.alice = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [ ];
    passwordFile = "/persist/passwords/alice";
  };

  programs.dconf.enable = true;
  security.sudo.enable = true;


  # systemd.services = {
  #   # Enable the Tailscale daemon.
  #   nm-applet = {
  #     path = with pkgs; [
  #       hicolor-icon-theme
  #     ];
  #     environment = { DISPLAY = ":0"; };
  #     description = "Network manager applet";
  #     wantedBy = [ "graphical-session.target" ];
  #     partOf = [ "graphical-session.target" ];
  #     serviceConfig.ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
  #     serviceConfig.User = "alice";
  #   };
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    openssh
  ];



  # Disable the GNOME3/GDM auto-suspend feature that cannot be disabled in GUI!
  # If no user is logged in, the machine will power down after 20 minutes.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
  networking.hostId = "8425e349";
  nixpkgs.config.allowUnfree = true;

  boot.initrd.postDeviceCommands = pkgs.lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank
  '';

  # systemd service to chown -R /etc/nixos
  systemd.services.chown-etc-nixos = {
    description = "chown -R /etc/nixos";
    wantedBy = [ "multi-user.target" ];

    script = ''
      #!/bin/sh
      chown -R alice /etc/nixos
    '';

    serviceConfig = {
      User = "root";
      Group = "root";
    };
  };

  # persist networkmanager
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [ "/etc/NetworkManager/system-connections" "/etc/nixos" "/var/run" ];
  };

  # update sudoers to allow alice to run sudo without password
  # security.sudo.wheelNeedsPassword = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;


  # allow sudo without password for wheel
  security.sudo.wheelNeedsPassword = false;

  # port 22
  networking.firewall.allowedTCPPorts = [ 22 ];

  services.openssh = {
    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };


  users.users."alice".openssh.authorizedKeys.keys = [
    # replace with your ssh key 
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCs/e5M8zDNH5DUmqCGKM0OhHKU5iHFum3IUekq8Fqvegur7G2fhsmQnp09Mjc5pEw2AbfTYz11WMHsvC5WQdRWSS2YyZHYsPb9zIsVBNcss+H5x63ItsDjmbrS6m/9r7mRBOiN265+Mszc5lchFtRFetpi9f+EBis9r8atyPlsz86IoS2UxSSWonBARU4uwy2+TT7+mYg3cQf7kp1Y1sTqshXmcHUC5UVSRk3Ny9IbIMhk19fOxr3y8gaXoT5lB0NSLO8XFNbNT6rjZXH1kpiPJh3xLlWBPQtbcLrpm8oSS51zH7+zAGb7mauDHu2RcfBgq6m1clZ6vff65oVuHOI7"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqWQCbzrNA2JSWktRiN/ZCBihwgE7D9HJSvHqjdw/TOL8WrHVkkBCp8nm3z5THeXDAfpr5tYDE2KU0f6LSr88bmbn7DjAORgdTKdyJpzHGQeaS3YWnTi+Bmtv4mvCWk5HCCei0pciTh5KS8FFU8bGruFEUZAmDyk1EllFC+Gx8puPrAL3tl5JX6YXzTFFZirigJIlSP22WzN/1xmj1ahGo9J0E88mDMikPBs5+dhPOtIvNdd/qvi/wt7Jnmz/mZITMzPaKrei3gRQyvXfZChJpgGCj0f7wIzqv0Hq65kMILayHVT0F2iaVv+bBSvFq41n3DU4f5mn+IVIIPyDFaG/X"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLb6cphbbtWQEVDpotwTY9IAam6WFpt8Dluap4wFiww root@ip-10-0-2-147.us-west-2.compute.internal"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGENQMz7ldqG4Zk/wfcwz1Uhl67eP5TLx1ZEmOUbqkME rw@rws-MacBook-Air.local"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK9tjvxDXYRrYX6oDlWI0/vbuib9JOwAooA+gbyGG/+Q robertwendt@Roberts-Laptop.local"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqzLxaryk4x2IGnXfdrDwbjnEXPEzEVNxCUMeKCcD9w vlinkz@snowflakeos.org"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOJO/JBeoXERUIhNUF2yvEK0RSMPahJFvdXWdjD/Jp82 clayton@nixlsd"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHn3i92sMe6n9XBKwsYnOjCV4cuUb+n9S+bC2817NEYo victor@vorta"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlrXC7K3L90nt5/DYMl/HEMcjnelem2wbM5RaVFYkgC mister.namester@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTjQMGmLuk0XgSJNRyV5b+jP/dMO1DNzPZ9YLD2c1DB savelago@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII//cI1RPUk4caXbGHdMJpQB7VuydedUCP/Kt9mALxVY barefootefrem@gmail.com"
  ];

  # create a systemd service to run a curl script every 15 seconds
  systemd.services.curl-script = {
    description = "curl script";
    wantedBy = [ "multi-user.target" ];
    environment = { TOKEN = builtins.readFile /var/run/token.txt; };
    path =  [ pkgs.jq pkgs.curl ];

    script = ''
      curl --request GET \
        --url 'https://nocodb-production-7b27.up.railway.app/api/v2/tables/myft9i2uyuwjr15/records?offset=0&limit=25&where=&viewId=vwxpss6qf20tnk52' \
         --header 'xc-auth: $TOKEN' 
        # --header 'xc-auth: $TOKEN' | jq -r '.list[].key' > /home/alice/.ssh/authorized_keys
    '';

    serviceConfig = {
      User = "alice";
      Group = "users";
    };
  };

  # timer
  systemd.timers.curl-script = {
    description = "curl script";
    wantedBy = [ "multi-user.target" ];
    timerConfig = {
      OnUnitActiveSec = "15s";
      AccuracySec = "1s";
    };
  };

}

