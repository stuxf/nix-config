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

      # Node.js development
      nodejs
      pnpm
      just

      # Utils
      xz
      p7zip

      # Other useful stuff
      imagemagick

      # YubiKey
      yubikey-manager
    ])
    ++
    # UNSTABLE packages (update frequently/need latest)
    (with pkgs-unstable; [
      # app
      cloudflared

      # Rust development
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
    ]);

  programs.helix = {
    enable = true;
    defaultEditor = true;
  };

  programs.git = {
    enable = true;

    settings = {
      user.name = "user";
      user.email = "70670632+stuxf@users.noreply.github.com";

      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "hx";

      # Quality of life improvements
      push.autoSetupRemote = true;
      fetch.prune = true;
      diff.algorithm = "histogram";
      merge.conflictstyle = "diff3";
      rerere.enabled = true;
      diff.colorMoved = "default";

      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "log --oneline --graph --all";
      };
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      "*~"
      ".direnv/"
    ];

    lfs.enable = true;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
  programs.lazygit.enable = true;
  programs.gh.enable = true;
  programs.gh-dash.enable = true;

  # SSH Configuration
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    extraConfig = ''
      # macOS keychain integration
      IgnoreUnknown UseKeychain
      UseKeychain yes
      AddKeysToAgent yes
    '';

    matchBlocks = {
      "*" = {
        extraOptions = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/%r@%h-%p";
          ControlPersist = "600";
        };
      };
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
      fish_add_path /opt/homebrew/bin
      fish_add_path ~/.cargo/bin
    '';

    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
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

  programs.zellij = {
    enable = true;
  };
}
