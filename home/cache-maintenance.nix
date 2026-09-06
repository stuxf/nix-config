{
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  bunCacheProject = pkgs.writeTextDir "package.json" "{}";

  weeklyCleanup = pkgs.writeShellApplication {
    name = "cache-clean-weekly";
    runtimeInputs = with pkgs; [
      bun
      nodejs
      pnpm
      uv
    ];
    text = ''
      uv cache prune || true
      pnpm store prune || true
      npm cache verify || true
      (cd ${bunCacheProject} && bun pm cache rm) || true
      /opt/homebrew/bin/brew cleanup --prune=30 || true
    '';
  };
in {
  home.packages = [weeklyCleanup];

  launchd.agents.cache-clean-weekly = {
    enable = true;
    config = {
      ProgramArguments = ["${weeklyCleanup}/bin/cache-clean-weekly"];
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 5;
          Minute = 0;
        }
      ];
      ProcessType = "Background";
      LowPriorityIO = true;
      Nice = 10;
      StandardOutPath = "${homeDir}/Library/Logs/cache-maintenance.log";
      StandardErrorPath = "${homeDir}/Library/Logs/cache-maintenance.log";
    };
  };
}
