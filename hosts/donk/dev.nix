# Coding: toolchains and language servers, globally. Projects pin their own
# versions with their language's tool (uv, pnpm/bun, rustup, go modules)
{
  inputs,
  username,
  ...
}: {
  # These ship several releases a week; stable would be weeks behind. Refresh
  # with `nix flake update nixpkgs-unstable` (also moves the Mac's cloudflared)
  nixpkgs.overlays = [
    (final: prev: let
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    in {
      inherit (unstable) claude-code codex;
    })
  ];

  # Run unpatched binaries (uv's Pythons, prebuilt wheels, downloaded tools)
  programs.nix-ld.enable = true;

  # Containers: rootless Docker only (DOCKER_HOST points at it)
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  home-manager.users.${username} = {pkgs, ...}: {
    # Bash for scripts and agents; fish stays the login shell
    programs.bash = {
      enable = true;
      enableCompletion = true;
    };

    # Python: `uv init`, `uv add`, `uv run`; the bare interpreter is for quick scripts
    programs.ruff = {
      enable = true;
      settings = {};
    };

    # `go install` puts tools here
    home.sessionPath = ["$HOME/go/bin"];

    home.packages = with pkgs; [
      # Python
      uv
      python3

      # JS
      nodejs
      yarn
      pnpm
      bun
      deno
      vscode-langservers-extracted # HTML/CSS/JSON LSPs

      # Go
      go
      gopls

      # Rust (toolchains per project via rust-toolchain.toml)
      rustup

      # C/C++
      clang-tools
      lldb
      gcc
      gdb
      valgrind
      cmake
      neocmakelsp
      gnumake
      checkmake
      codespell
      cppcheck
      doxygen
      gtest
      lcov

      # Zig
      zig
      zls

      # Typst
      typst
      tinymist
      typstyle

      # Nix
      nixd
      nil
      alejandra
      cloc

      # Agents
      claude-code
      codex
    ];
  };
}
