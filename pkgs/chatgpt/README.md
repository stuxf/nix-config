Vendored from nixpkgs PR #551713 ("chatgpt: support linux", head 294e967b),
since nixpkgs' `chatgpt` is still darwin-only. Delete this directory and the
overlay entry in flake.nix once that PR is merged and in our nixpkgs.
Update the pinned release with `./update.sh`, then build it before switching:
  nix build .#nixosConfigurations.donk.pkgs.chatgpt
Releases change layout without notice (26.924 moved the bundled tectonic,
fixed locally in package.nix).
