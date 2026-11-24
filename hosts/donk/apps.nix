# Apps
{username, ...}: {
  nixpkgs.overlays = [
    # Own package: nixpkgs' lags releases. Keeps the codex the app ships with
    (final: _: {
      chatgpt = final.callPackage ../../pkgs/chatgpt/package.nix {codex = null;};
    })
  ];

  home-manager.users.${username} = {pkgs, ...}: let
    # Idle Codex threads keep their MCP servers alive (openai/codex#11324)
    chatgptRestart = pkgs.writeShellApplication {
      name = "chatgpt-restart";
      runtimeInputs = with pkgs; [procps sway findutils coreutils gnugrep gnused];
      text = ''
        # $1: command, $2: its Codex home, $3: its --user-data-dir (empty for the default)
        restart() {
          local main="" pid profile
          for pid in $(pgrep -x ChatGPT); do
            if grep -qa -- '--type=' "/proc/$pid/cmdline"; then continue; fi
            profile=$(tr '\0' '\n' < "/proc/$pid/cmdline" | sed -n 's/^--user-data-dir=//p')
            if [ "$profile" = "$3" ]; then main=$pid; break; fi
          done
          if [ -z "$main" ]; then echo "$1 not running"; return 0; fi
          if [ "$(ps -o etimes= -p "$main" | tr -d ' ')" -lt 21600 ]; then echo "$1 started under 6h ago"; return 0; fi
          if find "$2/sessions" -name '*.jsonl' -mmin -30 -print -quit | grep -q .; then
            echo "$1: Codex active in the last 30 min; skipping"; return 0
          fi
          kill -TERM "$main"
          for _ in $(seq 60); do kill -0 "$main" 2>/dev/null || break; sleep 1; done
          if kill -0 "$main" 2>/dev/null; then echo "$1 did not exit"; return 1; fi
          SWAYSOCK=''${socks[0]} swaymsg exec "$1"
          echo "Restarted $1"
        }
        socks=("/run/user/$(id -u)"/sway-ipc.*.sock)
        status=0
        restart chatgpt "$HOME/.codex" "" || status=1
        restart chatgpt-2 "$HOME/.codex-2" "$HOME/.config/ChatGPT-2" || status=1
        exit "$status"
      '';
    };

    # Second account: own ChatGPT profile and Codex home
    chatgpt2 = pkgs.writeShellApplication {
      name = "chatgpt-2";
      text = ''
        export CODEX_HOME=$HOME/.codex-2 CODEX_ELECTRON_USER_DATA_PATH=$HOME/.config/ChatGPT-2
        exec ${pkgs.chatgpt}/bin/chatgpt --user-data-dir="$CODEX_ELECTRON_USER_DATA_PATH" "$@"
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

    xdg.desktopEntries.chatgpt-2 = {
      name = "ChatGPT 2";
      exec = "chatgpt-2 %U";
      icon = "chatgpt";
      categories = ["Utility" "Development"];
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
      chatgpt2

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
