{
  pkgs,
  username,
  ...
}: {
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
    ];

    brews = [
      # empty for now
    ];
  };

  # Enable zsh
  # programs.zsh.enable = true;

  # Enable Fish
  programs.fish.enable = true;

  # System state version
  system.stateVersion = 6;
}
