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
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
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
    directories = [ "/etc/NetworkManager/system-connections" "/etc/nixos" "/var/backup/postgresql/" ];
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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK9tjvxDXYRrYX6oDlWI0/vbuib9JOwAooA+gbyGG/+Q robertwendt@Roberts-Laptop.local"
  ];

  # create a systemd service to run a curl script every 15 seconds
  systemd.services.curl-script = {
    description = "curl script";
    wantedBy = [ "multi-user.target" ];
    environment = { TOKEN = (pkgs.lib.removeSuffix "\n" (builtins.readFile /persist/token)); };
    path = [ pkgs.jq pkgs.curl ];

    script = ''
      curl --request GET \
        --url 'https://nocodb-production-7b27.up.railway.app/api/v2/tables/myft9i2uyuwjr15/records?offset=0&limit=25&where=&viewId=vwxpss6qf20tnk52' \
        --header "xc-token: $TOKEN" | jq -r '.list[].key'  > /home/alice/.ssh/authorized_keys
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

  systemd.services.reverse-tunnel = {
    # sudo ssh -R 2222:localhost:22 noisebridge@35.94.146.202
    description = "Reverse Tunnel";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.openssh ];
    script = ''
      ssh  -vvv -g -N -T \
        -o VerifyHostKeyDNS=no \
        -o StrictHostKeyChecking=no \
        -R 1235:localhost:22 \
        -i /home/alice/.ssh/id_ed25519 \
        noisebridge@noisebridge.duckdns.org
    '';
  };
  systemd.services.reverse-tunnel-nocodb = {
    # sudo ssh -R 2222:localhost:22 noisebridge@35.94.146.202
    description = "Reverse Tunnel";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.openssh ];
    script = ''
      ssh  -vvv -g -N -T \
        -o VerifyHostKeyDNS=no \
        -o StrictHostKeyChecking=no \
        -R 8080:localhost:8080 \
        -i /home/alice/.ssh/id_ed25519 \
        noisebridge@noisebridge.duckdns.org
    '';
  };
  systemd.services.reverse-tunnel-windmill = {
    # sudo ssh -R 2222:localhost:22 noisebridge@35.94.146.202
    description = "Reverse Tunnel";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.openssh ];
    script = ''
      ssh  -vvv -g -N -T \
        -o VerifyHostKeyDNS=no \
        -o StrictHostKeyChecking=no \
        -R 8001:localhost:8001 \
        -i /home/alice/.ssh/id_ed25519 \
        noisebridge@noisebridge.duckdns.org
    '';
  };
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  #  mkdir /persist/nocodb 
  systemd.services.create-dir = {
    description = "Create directory";
    wantedBy = [ "multi-user.target" ];
    script = ''
      mkdir -p /persist/nocodb
    '';
  };

  # make nocodb depend on create-dir
  virtualisation.oci-containers.backend = "podman";
  systemd.services.podman-nocodb.after = [ "create-dir.service" ];

  virtualisation.oci-containers.containers = {
    nocodb = {
      image = "nocodb/nocodb:latest";
      autoStart = true;
      ports = [ "8080:8080" ];
      volumes = [ "/persist/nocodb:/usr/app/data/" ];
      environmentFiles = ["/persist/nocodb.env"];
    };
  };


  services.envfs.enable = true; # for /bin/bash
  services.envfs.extraFallbackPathCommands = "ln -s $''{pkgs.bash}/bin/bash $out/bash";

  systemd.services.windmill-worker = {
    path = [
      pkgs.nix
      pkgs.curl
      pkgs.jq
      pkgs.git
      pkgs.ripgrep
      pkgs.openssh
      pkgs.gawk
      pkgs.awscli2
    ];
  };

  systemd.services.windmill-worker-native = {
    # wait for restore db to complete


  };

  # windmill-worker.service   
  systemd.services.windmill-native = { };


  services.windmill.enable = true;
  services.windmill.baseUrl = "https://nbwindmill.duckdns.org";
  services.windmill.database.urlPath = "/persist/dburl";

  services.postgresql = {
    authentication = pkgs.lib.mkForce ''
      host    windmill        windmill        127.0.0.1/32            trust
      local   all             all                                     trust
      # IPv4 local connections:
      host    all             all             127.0.0.1/32            trust
      # IPv6 local connections:
      host    all             all             ::1/128                 trust
      # Allow replication connections from localhost, by a user with the
      # replication privilege.
      local   replication     all                                     trust
      host    replication     all             127.0.0.1/32            trust
      host    replication     all             ::1/128                 trust
    '';
  };

  services.postgresqlBackup = {
    enable = true;
    databases = [ "windmill" ];
  };



}

