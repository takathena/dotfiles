# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

let
  # Channel unstable, dipakai khusus untuk paket Dux Shell
  # (channel ini harus sudah didaftarkan: sudo nix-channel --add
  #  https://nixos.org/channels/nixos-unstable nixos-unstable)
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
  zen = (builtins.getFlake "github:youwen5/zen-browser-flake").packages.x86_64-linux.default;
in
{
  # Matikan modul lama (dms-*) dari channel stable 26.05, karena diganti
  # modul dux-* dari unstable di bawah. Kalau tidak dimatikan, opsinya bentrok.
  disabledModules = [
    "programs/wayland/dms-shell.nix"
    "services/display-managers/dms-greeter.nix"
  ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Modul Dux Shell dan Dux Greeter dari nixpkgs unstable
      <nixos-unstable/nixos/modules/programs/wayland/dux-shell.nix>
      <nixos-unstable/nixos/modules/services/display-managers/dux-greeter.nix>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 6;
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."takathena" = {
    isNormalUser = true;
    description = "takathena";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [unstable.dux-shell];
    #packages = [unstable.dux-shell];
    # Shell default user: fish (programs.fish.enable harus aktif, lihat di bawah)
    shell = pkgs.fish;
  };

   programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    unstable.dux-search
    unstable.dux-files
    unstable.dux-calendar
    unstable.dux-gop
    git
    wget
    curl
    unzip
    tree
    brightnessctl   # atur kecerahan layar
    fish
    alacritty       # terminal untuk di dalam niri
    zen
    tailscale
  ];

  # Mengaktifkan fish dengan benar di level sistem
  programs.fish.enable = true;
  services.tailscale.enable = true;  

  # Mengaktifkan perintah `nix ...` baru dan flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  #Garbage collection otomatis
  nix.gc = {
   automatic = true;
   dates = "weekly";
   options = "--delete-older-than 14d";
  };
  
  nix.settings.auto-optimise-store = true;

  # ==========================================================
  # Desktop: niri + Dux Shell
  # ==========================================================

  # Compositor niri (tiling Wayland)
  programs.niri.enable = true;

  # Dux Shell (bar, notifikasi, launcher, lock screen, dll.)
  # Modul dux-shell diimpor dari nixpkgs unstable (lihat bagian imports),
  # paketnya juga dari unstable (dux-shell 2.1.1).
  programs.dux-shell = {
    enable = true;
    systemd.enable = true;           # otomatis jalan saat masuk sesi niri
    package = unstable.dux-shell;
  };

  # Layar login, langsung membuka sesi niri.
  # Modul dux-greeter diimpor dari unstable, jadi paketnya juga harus
  # dari unstable (default modul memakai pkgs.dux-greeter yang tidak ada
  # di stable 26.05).
  services.displayManager.dux-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/takathena";  # sinkronkan tema dengan greeter
    package = unstable.dux-greeter;
  };

  # Popup minta password admin untuk aplikasi grafis
  security.polkit.enable = true;

  # Audio (dibutuhkan widget volume Dux Shell)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Font (Nerd Font dibutuhkan supaya ikon di bar tampil)
  fonts.packages = with pkgs; [
    noto-fonts
    nerd-fonts.jetbrains-mono
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
