# Games
{
  pkgs,
  username,
  ...
}: {
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
  };
  programs.gamemode.enable = true;

  home-manager.users.${username}.home.packages = with pkgs; [
    heroic # Epic / GOG
    bottles # other Windows games and apps
    prismlauncher # Minecraft
  ];
}
