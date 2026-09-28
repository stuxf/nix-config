# Home Manager settings shared by air (macOS) and donk (NixOS)
{
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
in {
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

    settings = {
      "*" = {
        IgnoreUnknown = "UseKeychain";
        UseKeychain = "yes";
        AddKeysToAgent = "yes";
        ControlMaster = "auto";
        ControlPath = "~/.ssh/sockets/%r@%h-%p";
        ControlPersist = "600";
      };
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/github_ed25519";
        IdentitiesOnly = true;
      };
    };
  };

  # Fish
  programs.fish = {
    enable = true;

    # mkAfter: keep these after the fzf/zoxide/atuin init lines, as before
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
      cat = "bat";
      cd = "z";
      rebuild =
        if isDarwin
        then "sudo darwin-rebuild switch --flake ~/nix-config#air"
        else "sudo nixos-rebuild switch --flake ~/nix-config#donk";
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
    shellWrapperName = "yy";
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zellij = {
    enable = true;
  };

  programs.tmux = {
    enable = true;
  };
}
