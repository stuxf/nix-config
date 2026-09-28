# donk's home-manager config
{
  lib,
  username,
  ...
}: {
  imports = [../../home/common.nix];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  # Release of the first home-manager setup on this machine; don't change
  home.stateVersion = "24.05";

  programs.ssh.settings = {
    # Remote hosts rarely have foot's terminfo
    "*".SetEnv.TERM = "xterm-256color";
    # This machine's GitHub key
    "github.com".IdentityFile = lib.mkForce "~/.ssh/id_ed25519";
  };
  # For the shared ControlPath
  home.file.".ssh/sockets/.keep".text = "";
}
