# Dev tools
{
  pkgs,
  username,
  ...
}: {
  # From unstable (stable lags weeks); in place so ChatGPT uses this codex
  nixpkgs.overlays = [
    (final: prev: {
      inherit (final.unstable) claude-code codex;
    })
  ];

  programs.nix-ld.enable = true;
  # /bin and /usr/bin show everything on PATH, for scripts hard-coding /bin/bash etc.
  services.envfs.enable = true;

  # Rootless Podman; `docker` runs podman, and Docker SDKs/compose use its API socket
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  systemd.user.sockets.podman.wantedBy = ["sockets.target"];
  environment.extraInit = ''
    if [ -z "$DOCKER_HOST" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
      export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
    fi
  '';
  environment.systemPackages = [pkgs.docker-compose];

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
      - Containers: rootless Podman. `docker` is an alias for it and works
        without sudo; Docker SDKs and compose reach it via DOCKER_HOST.
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
