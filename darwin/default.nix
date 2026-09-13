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
  determinateNix.determinateNixd.garbageCollector.strategy = "automatic";

  determinateNix.customSettings = {
    eval-cores = 0; # Parallel evaluation
    sandbox = true;
    extra-experimental-features = [
      "parallel-eval"
    ];
  };

  # Determinate Nix collects unreferenced paths under disk pressure, but leaves
  # profile generation retention to the user. Expire old generations weekly.
  launchd.daemons.nix-gc.serviceConfig = {
    ProgramArguments = [
      "/nix/var/nix/profiles/default/bin/nix-collect-garbage"
      "--delete-older-than"
      "14d"
    ];
    StartCalendarInterval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
    StandardOutPath = "/var/log/nix-gc.log";
    StandardErrorPath = "/var/log/nix-gc.log";
  };

  launchd.daemons.nix-optimise.serviceConfig = {
    ProgramArguments = [
      "/nix/var/nix/profiles/default/bin/nix"
      "store"
      "optimise"
    ];
    StartCalendarInterval = {
      Weekday = 0;
      Hour = 4;
      Minute = 0;
    };
    StandardOutPath = "/var/log/nix-optimise.log";
    StandardErrorPath = "/var/log/nix-optimise.log";
  };

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    brews = [
      "pkg-config"
      "openssl@3"
      "ffmpeg"
      "container"
    ];

    casks = [
      # Browsers
      "google-chrome"

      # Terminal
      "ghostty"

      # Text editor
      "coteditor"

      # Communication
      "vesktop"
      "signal"
      "telegram"
      "slack"

      # Music
      "spotify"

      # Media Player
      "iina"

      # Study
      "anki"

      # VPN
      "cloudflare-warp"

      # Containers
      "orbstack"

      # Dev stuff
      "android-studio"
      "notion-cli"
      "tailscale-app"

      # AI
      "claude"
      "chatgpt"

      # AI CLI
      "claude-code"
      "codex"

      # Games
      "prismlauncher"
      "steam"

      # Game Dev ;)
      "godot"
    ];
  };

  # Enable Fish
  programs.fish.enable = true;

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
  };

  # Fonts
  fonts.packages = with pkgs; [
    # Nerd Fonts (with icons/glyphs for terminals)
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg

    # Regular versions (optional)
    fira-code
    # jetbrains-mono
  ];

  # System state version
  system.stateVersion = 6;
}
