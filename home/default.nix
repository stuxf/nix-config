{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.stateVersion = "25.05";

  home.packages =
    # STABLE packages (won't break)
    (with pkgs; [
      # Fun stuff
      krabby
      fastfetch

      # CLI tools
      fzf
      hyperfine
      tokei
      tealdeer

      # Nix tools
      alejandra # Formatter
      comma # Run commands without installing

      # Modern CLI replacements
      ripgrep
      fd
      bat
      eza
      dust

      # Python stuff
      uv
      python314

      # Utils
      xz
      p7zip

      # Git++
      gh
      gh-dash
      lazygit
      gitui

      # Other useful stuff
      imagemagick

      # YubiKey
      yubikey-manager
    ])
    ++
    # UNSTABLE packages (update frequently/need latest)
    (with pkgs-unstable; [
      # AI Tools
      claude-code
      codex
      gemini-cli
    ]);

  programs.helix = {
    enable = true;
    defaultEditor = true;
  };

  programs.git = {
    enable = true;
    userName = "user";
    userEmail = "70670632+stuxf@users.noreply.github.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "hx";
    };

    lfs.enable = true;
  };

  programs.git.delta.enable = true;
  programs.lazygit.enable = true;
  programs.gitui.enable = true;
  programs.gh.enable = true;
  programs.gh-dash.enable = true;

  # SSH Configuration
  programs.ssh = {
    enable = true;

    extraConfig = ''
      # macOS keychain integration
      IgnoreUnknown UseKeychain
      UseKeychain yes
      AddKeysToAgent yes
    '';

    matchBlocks = {
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/github_ed25519";
        identitiesOnly = true;
      };
    };
  };

  # Fish
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting ""
      krabby random
    '';

    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      tree = "eza -T";
      cat = "bat";
      cd = "z";
      rebuild = "sudo darwin-rebuild switch --flake ~/nix-config#air";
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.starship = {
    enable = true;
    settings.add_newline = false;
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bat.enable = true;
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.btop.enable = true;
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };
}
