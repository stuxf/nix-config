# Shared by air and donk
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
  # unfree, so always built locally; skip the slow tests
  terraformNoCheck = pkgs.unstable.terraform.overrideAttrs (_: {
    doCheck = false;
  });
in {
  # Its options.json trips a Nix warning on every rebuild; docs are online
  manual.manpages.enable = false;

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

    signing = {
      format = "ssh";
      key = "${config.home.homeDirectory}/.ssh/${
        if isDarwin
        then "github_ed25519"
        else "id_ed25519"
      }";
      signByDefault = true;
    };
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

    settings = {
      "*" =
        {
          SetEnv.TERM = "xterm-256color";
          AddKeysToAgent = "yes";
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/%r@%h-%p";
          ControlPersist = "600";
        }
        // lib.optionalAttrs isDarwin {
          IgnoreUnknown = "UseKeychain";
          UseKeychain = "yes";
        };
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/github_ed25519";
        IdentitiesOnly = true;
      };
    };
  };

  home.file.".ssh/sockets/.keep".text = "";

  # Fish
  programs.fish = {
    enable = true;

    interactiveShellInit = lib.mkAfter (
      ''
        set fish_greeting ""
        krabby random
      ''
      + lib.optionalString isDarwin ''
        fish_add_path /opt/homebrew/bin
      ''
    );

    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      tree = "eza --tree";
      claude = "claude --allow-dangerously-skip-permissions";
      cat = "bat";
      cd = "z";
      rebuild =
        if isDarwin
        then "sudo darwin-rebuild switch --flake ~/nix-config#air"
        else "nixos-rebuild switch --flake ~/nix-config#donk --sudo";
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
    shellWrapperName = "y";
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.nix-index-database.comma.enable = true;

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    mouse = true;
    baseIndex = 1;
    escapeTime = 10;
    historyLimit = 100000;
    focusEvents = true;
    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB,xterm-ghostty:RGB,foot:RGB"
      set -g extended-keys on
      set -as terminal-features "xterm*:extkeys"
      set -g set-clipboard on
      set -g allow-passthrough on
      set -g renumber-windows on
      set -ga update-environment " WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP"
      set -g monitor-bell on
      set -g bell-action other
    '';
  };

  home.sessionPath = ["$HOME/go/bin"];

  home.packages = with pkgs; [
    # Fun
    krabby
    fastfetch

    # CLI
    hyperfine
    tokei
    just
    tealdeer
    jq
    fx
    ripgrep
    fd
    eza
    dust
    xz
    p7zip
    imagemagick

    # Nix
    alejandra
    nixd
    nil

    # Languages
    uv
    nodejs
    pnpm
    bun
    go
    gopls
    rustup
    typescript
    typescript-language-server
    vscode-langservers-extracted # HTML/CSS/JSON

    # Typst
    typst
    tinymist
    typstyle

    # Cloud / infra
    awscli2
    terraformNoCheck
    packer
    unstable.cloudflared

    # Security scanning
    trivy
    osv-scanner
    syft
    grype

    # YubiKey
    yubikey-manager
  ];
}
