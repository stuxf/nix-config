Vendored from nixpkgs PR #551713 (Linux support); delete this directory and
its overlay once that lands. Update with `./update.sh`, then build:
  nix build .#nixosConfigurations.donk.pkgs.chatgpt
