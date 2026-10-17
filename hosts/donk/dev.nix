# Dev tools
{
  inputs,
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
    if [ -n "$XDG_RUNTIME_DIR" ]; then
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

    # Computer use MCP server (`cua-driver mcp`); telemetry and update check off
    cuaDriver = pkgs.writeShellApplication {
      name = "cua-driver";
      # wtype: keyboard input on Sway
      runtimeInputs = [pkgs.wtype];
      text = ''
        export DO_NOT_TRACK=1 CUA_DRIVER_RS_UPDATE_CHECK=false CUA_DRIVER_RS_ENABLE_WAYLAND=1
        # current sway session, even from a shell that predates it
        while IFS= read -r kv; do export "''${kv?}"; done < <(
          systemctl --user show-environment | grep -E '^(WAYLAND_DISPLAY|DISPLAY|SWAYSOCK)='
        )
        # NixOS sets these to turn app accessibility off; apps the driver launches need it on
        unset NO_AT_BRIDGE GTK_A11Y
        exec ${inputs.cua.packages.${pkgs.stdenv.hostPlatform.system}.cua-driver}/bin/cua-driver "$@"
      '';
    };
  in {
    home.file.".claude/CLAUDE.md".text = agentInstructions;
    home.file.".codex/AGENTS.md".text = agentInstructions;

    programs.bash = {
      enable = true;
      enableCompletion = true;
    };

    # Podman puts every rootless container in this slice: one cap for all of them
    systemd.user.slices.user.Slice = {
      MemoryHigh = "6G";
      MemoryMax = "8G";
    };

    # Prune what killed or crashed runs leave behind
    systemd.user.services.podman-prune = {
      Unit.Description = "Prune stale Podman containers, images and volumes";
      Service = {
        Type = "oneshot";
        ExecStart = [
          "/run/current-system/sw/bin/podman container prune -f --filter until=24h"
          "/run/current-system/sw/bin/podman image prune -f"
          "/run/current-system/sw/bin/podman volume prune -f --filter until=336h"
        ];
      };
    };
    systemd.user.timers.podman-prune = {
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
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
      cuaDriver
    ];
  };
}
