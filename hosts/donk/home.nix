{username, ...}: {
  imports = [../../home/common.nix];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.05";
}
