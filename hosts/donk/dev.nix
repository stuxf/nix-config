# Dev tools
{username, ...}: {
  # From unstable (stable lags weeks); in place so ChatGPT uses this codex
  nixpkgs.overlays = [
    (final: prev: {
      inherit (final.unstable) claude-code codex;
    })
  ];

  programs.nix-ld.enable = true;

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  home-manager.users.${username} = {pkgs, ...}: let
    agentInstructions = ''
      # This machine (donk)

      - NixOS, not a regular Linux distro: there is no apt/dnf/pacman, and
        nothing global goes in /usr. Don't try to install system packages.
      - Missing a tool? Run it without installing: `, <command>` (comma), or
        `nix shell nixpkgs#<package> -c <command>`.
      - Project dependencies stay in the project: `uv` for Python (never global
        `pip install`), pnpm/bun for JS, rustup, go modules. For system
        libraries or other tools, add a `flake.nix` devShell plus an `.envrc`
        containing `use flake` (direnv is set up).
      - Prebuilt binaries (downloaded CLIs, pip wheels) work thanks to nix-ld.
      - Docker is rootless: `docker` works without sudo.
      - No sudo: it needs the owner's password. Don't edit /etc.
      - System config is the flake in ~/nix-config. Don't commit there and
        don't run `rebuild`; propose changes and let the owner apply them.
    '';
  in {
    home.file.".claude/CLAUDE.md".text = agentInstructions;
    home.file.".codex/AGENTS.md".text = agentInstructions;

    programs.bash = {
      enable = true;
      enableCompletion = true;
    };

    home.packages = with pkgs; [
      # Python
      python3

      # C/C++
      clang-tools
      gcc
      gdb
      cmake
      gnumake

      # Zig
      zig
      zls

      # Agents
      claude-code
      codex
    ];
  };
}
