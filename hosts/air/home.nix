{pkgs, ...}: {
  imports = [
    ../../home/common.nix
    ./cache-maintenance.nix
    ./default-apps.nix
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    python314
    duti
  ];
}
