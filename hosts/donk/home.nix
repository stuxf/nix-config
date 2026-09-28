{
  lib,
  username,
  ...
}: {
  imports = [../../home/common.nix];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.05";

  programs.ssh.settings."github.com".IdentityFile = lib.mkForce "~/.ssh/id_ed25519";
}
