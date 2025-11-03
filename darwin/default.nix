{
  pkgs,
  username,
  ...
}: {
  imports = [
    ./yabai.nix
    ./system-defaults.nix
  ];

  # User configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.fish;
  };

  system.primaryUser = username;

  environment.shells = [pkgs.fish];

  # Allow unfree packages (Discord, spotify, etc.)
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Add system-level tools here if needed
    helix
    tree
  ];

  # Let Determinate Nix handle Nix Configuration
  nix.enable = false;

  # Custom Determinate Settings
  determinate-nix.customSettings = {
    eval-cores = 0; # Parallel evaluation
    extra-experimental-features = [
      "parallel-eval"
    ];
  };

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    casks = [
      # Browsers
      "firefox"
      "google-chrome"

      # Terminal
      "ghostty"

      # Communication
      "vesktop"
      "signal"
      "telegram"
      "slack"

      # Music
      "spotify"

      # VPN
      "cloudflare-warp"

      # Containers
      "orbstack"
    ];
  };

  # Enable Fish
  programs.fish.enable = true;

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Fonts
  fonts.packages = with pkgs; [
    # Nerd Fonts (with icons/glyphs for terminals)
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg

    # Regular versions (optional)
    fira-code
    jetbrains-mono
  ];

  # System state version
  system.stateVersion = 6;
}
