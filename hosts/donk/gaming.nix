# Games: Steam (with Proton-GE and gamescope), gamemode, and other launchers
{
  pkgs,
  username,
  ...
}: {
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    # Proton-GE, selectable per game in Steam's compatibility settings
    extraCompatPackages = [pkgs.proton-ge-bin];
  };
  programs.gamemode.enable = true;

  home-manager.users.${username}.home.packages = with pkgs; [
    heroic # Epic / GOG
    bottles # other Windows games and apps
    prismlauncher # Minecraft
  ];
}
