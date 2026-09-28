{
  pkgs,
  pkgs-unstable,
  ...
}: let
  terraformNoCheck = pkgs-unstable.terraform.overrideAttrs (_: {
    doCheck = false;
  });
in {
  imports = [
    ./common.nix
    ./cache-maintenance.nix
    ./default-apps.nix
  ];

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
      awscli2
      terraformNoCheck
      packer

      # Security scanning
      trivy
      osv-scanner
      syft
      grype

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
      bun
      just
      typescript
      typescript-language-server

      # Go development
      go
      gopls

      # Rust development
      rustup

      # Utils
      duti
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
    ]);
}
