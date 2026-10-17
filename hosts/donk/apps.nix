# Apps
{username, ...}: {
  nixpkgs.overlays = [
    # until nixpkgs#551713 lands
    (final: prev: {
      # bundled codex; nixpkgs' lags behind (gpt-6.1-sol needs >= 0.159.2)
      chatgpt = final.callPackage ../../pkgs/chatgpt/package.nix {codex = null;};
    })
  ];

  home-manager.users.${username} = {pkgs, ...}: let
    # Idle Codex threads keep their MCP servers alive (openai/codex#11324)
    chatgptRestart = pkgs.writeShellApplication {
      name = "chatgpt-restart";
      runtimeInputs = with pkgs; [procps sway findutils coreutils gnugrep];
      text = ''
        main=""
        for pid in $(pgrep -x ChatGPT); do
          if ! grep -qa -- '--type=' "/proc/$pid/cmdline"; then main=$pid; break; fi
        done
        if [ -z "$main" ]; then echo "ChatGPT not running"; exit 0; fi
        if [ "$(ps -o etimes= -p "$main" | tr -d ' ')" -lt 21600 ]; then echo "Started under 6h ago"; exit 0; fi
        if find "$HOME/.codex/sessions" -name '*.jsonl' -mmin -30 -print -quit | grep -q .; then
          echo "Codex active in the last 30 min; skipping"; exit 0
        fi
        kill -TERM "$main"
        for _ in $(seq 60); do kill -0 "$main" 2>/dev/null || break; sleep 1; done
        if kill -0 "$main" 2>/dev/null; then echo "ChatGPT did not exit"; exit 1; fi
        socks=("/run/user/$(id -u)"/sway-ipc.*.sock)
        SWAYSOCK=''${socks[0]} swaymsg exec chatgpt
        echo "Restarted ChatGPT"
      '';
    };
  in {
    systemd.user.services.chatgpt-restart = {
      Unit.Description = "Restart ChatGPT when Codex is idle";
      Service = {
        Type = "oneshot";
        ExecStart = "${chatgptRestart}/bin/chatgpt-restart";
      };
    };
    systemd.user.timers.chatgpt-restart = {
      Timer.OnCalendar = "*-*-* 04,05,06:00:00";
      Install.WantedBy = ["timers.target"];
    };

    # use pcscd, so ykman can share the YubiKey
    programs.gpg = {
      enable = true;
      scdaemonSettings.disable-ccid = true;
    };
    services.gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-gnome3;
    };

    home.packages = with pkgs; [
      # Chat and media
      vesktop
      spotify
      telegram-desktop
      signal-desktop
      zapzap # WhatsApp
      notion-app-enhanced
      chatgpt

      # Office
      libreoffice
      hunspell

      # Hobby / school
      pinta
      godot

      # Misc CLI
      file
      which
      zip
      unzip
      wl-clipboard
    ];
  };
}
