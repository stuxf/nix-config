# donk: ASUS Zephyrus G14 (GA401QM), NixOS
{
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ./devbox.nix
    ./desktop.nix
    ./browsers.nix
    ./gaming.nix
    ./dev.nix
    ./apps.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      configurationLimit = 5;
    };
  };

  networking.hostName = "donk";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # Sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.printing.enable = true;
  services.cloudflare-warp.enable = true;
  # Resolve tailnet names outside WARP
  systemd.services.warp-tailnet-dns = {
    description = "Resolve tailnet names outside WARP";
    after = ["cloudflare-warp.service"];
    wants = ["cloudflare-warp.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.cloudflare-warp pkgs.gnugrep];
    script = ''
      warp-cli --accept-tos dns fallback list | grep -qw 'ts\.net' ||
        warp-cli --accept-tos dns fallback add ts.net
    '';
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [vim git helix wget];

  # Determinate otherwise points nixpkgs at nixpkgs-weekly
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.channel.enable = false;
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # Release of the first install; don't change (see `man configuration.nix`)
  system.stateVersion = "24.11";
}
