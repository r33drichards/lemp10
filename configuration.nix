# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

let
  impermanence = builtins.fetchTarball "https://github.com/nix-community/impermanence/archive/master.tar.gz";
in
{


  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      "${impermanence}/nixos.nix"
      (fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")

    ];

  services.vscode-server.enable = true;


  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

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
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [ ];
    passwordFile = "/persist/passwords/alice";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    emacs
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
        ms-python.python
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
        github.copilot
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "remote-ssh-edit";
          publisher = "ms-vscode-remote";
          version = "0.47.2";
          sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
        }
      ];
    })
    sbclPackages.stumpwm
    google-chrome
    gnome.gnome-terminal
    git
    openssh
    slack
    nixpkgs-fmt
  ];
  programs.direnv.enable = true;

  systemd.services.clone-repos = {
    description = "Clone repositories to /home/alice";
    wantedBy = [ "multi-user.target" ];

    script = ''
      #!/bin/sh
      # add ssh to path
      export PATH=$PATH:${pkgs.openssh}/bin
      cd /home/alice || exit
      # clone if not exists
      if [ ! -d "dotfiles" ]; then
        ${pkgs.git}/bin/git clone git@gitlab.com:reedrichards/dotfiles.git
      fi
      # Add more repositories as needed
    '';

    serviceConfig = {
      User = "alice";
      Group = "users"; # or set it to alice's primary group
    };
  };

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
  services.tailscale.enable = true;


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
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/nixos"
    ];
  };

  # update sudoers to allow alice to run sudo without password
  security.sudo.wheelNeedsPassword = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # enable tailscale up on boot
  # auth key can be found in /persist/ts/authkey

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up --ssh -authkey `cat /persist/ts/authkey`
    '';
  };


}

