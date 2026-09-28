Vendored from nixpkgs PR #551713 ("chatgpt: support linux", head 294e967b),
since nixpkgs' `chatgpt` is still darwin-only. Delete this directory and the
overlay entry in flake.nix once that PR is merged and in our nixpkgs.
Update the pinned release with `./update.sh`, then build it before switching:
  nix build .#nixosConfigurations.donk.pkgs.chatgpt
Releases change layout without notice (26.924 moved the bundled tectonic,
fixed locally in package.nix).

HOLD (2026-09-27): Linux is pinned to 26.917.71314 because 26.924.x hangs on
"Starting your task" (openai/codex#48486, #48602). Don't run ./update.sh until
a fixed release is out; it would bump Linux back to 26.924.

Local change: package.nix generates the Chrome plugin's native messaging host
(share/chatgpt/native-messaging-hosts/, linked from hosts/donk/apps.nix), which
the app itself never installs on Linux.
