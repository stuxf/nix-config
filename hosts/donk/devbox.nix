# Always-on remote devbox
{
  pkgs,
  username,
  ...
}: {
  services.tailscale = {
    enable = true;
    extraSetFlags = ["--ssh"];
  };
  networking.firewall.trustedInterfaces = ["tailscale0"];

  # Never sleep
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  networking.networkmanager.wifi.powersave = false;
  networking.networkmanager.settings.main.autoconnect-retries-default = 0;

  # Reboot if the kernel hangs
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "30s";
    RebootWatchdogSec = "10min";
  };

  systemd.oomd.enableUserSlices = true;

  # Keep agent builds from starving the box
  nix.settings = {
    max-jobs = 4;
    cores = 4;
    min-free = 20 * 1024 * 1024 * 1024;
    max-free = 60 * 1024 * 1024 * 1024;
  };
  nix.daemonCPUSchedPolicy = "batch";
  nix.daemonIOSchedClass = "idle";
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "9G";
    MemoryMax = "11G";
  };

  home-manager.users.${username} = {
    config,
    pkgs,
    ...
  }: let
    tmux = "${config.programs.tmux.package}/bin/tmux";

    # After each resurrect save: record the Claude / Codex session in each pane
    agentsSave = pkgs.writeShellScript "tmux-agents-save" ''
      set -u
      dir=$(${tmux} show -gqv @agents-state-dir); dir=''${dir:-$HOME/.local/state/tmux-agents}
      mkdir -p "$dir"
      declare -A pos
      while read -r pid p; do pos[$pid]=$p; done \
        < <(${tmux} list-panes -a -F '#{pane_pid} #{session_name}:#{window_index}.#{pane_index}')
      pane_of() {
        local p=$1
        while [ -n "$p" ] && [ "$p" -gt 1 ]; do
          [ -n "''${pos[$p]:-}" ] && { echo "''${pos[$p]}"; return; }
          p=$(sed 's/.*) //' "/proc/$p/stat" 2>/dev/null | cut -d' ' -f2)
        done
      }
      keep() {
        local tool=$1; shift; local out=()
        while [ $# -gt 0 ]; do
          case "$tool:$1" in
            claude:--dangerously-skip-permissions | claude:--allow-dangerously-skip-permissions | \
            claude:--chrome | claude:--no-chrome | codex:--yolo | codex:--search | \
            codex:--dangerously-bypass-approvals-and-sandbox) out+=("$1") ;;
            claude:--permission-mode | claude:--model | codex:-m | codex:--model | codex:-s | \
            codex:--sandbox | codex:-a | codex:--ask-for-approval) out+=("$1" "''${2:-}"); shift ;;
          esac
          shift
        done
        echo "''${out[*]:-}"
      }
      tmp=$(mktemp "$dir/.panes.XXXXXX")
      for d in /proc/[0-9]*; do
        pid=''${d#/proc/}
        mapfile -d "" -t argv < "$d/cmdline" 2>/dev/null || continue
        [ ''${#argv[@]} -gt 0 ] || continue
        name=''${argv[0]##*/}; sid=""; tool=""
        case "$name" in
          claude | .claude-wrapped)
            tool=claude
            sid=$(${pkgs.jq}/bin/jq -r '.sessionId // empty' "$HOME/.claude/sessions/$pid.json" 2>/dev/null) ;;
          codex | .codex-wrapped)
            case "''${argv[1]:-}" in "" | -* | resume) ;; *) continue ;; esac
            tool=codex
            sid=$(for f in "$d"/fd/*; do readlink "$f"; done 2>/dev/null |
              grep -o 'rollout-.*-[0-9a-f-]\{36\}\.jsonl$' | tail -1 |
              grep -o '[0-9a-f-]\{36\}\.jsonl$' | sed 's/\.jsonl$//') ;;
          *) continue ;;
        esac
        p=$(pane_of "$pid"); [ -n "$p" ] || continue
        printf '%s\t%s\t%s\t%s\n' "$p" "$tool" "$sid" "$(keep "$tool" "''${argv[@]:1}")" >> "$tmp"
      done
      mv "$tmp" "$dir/panes.tsv"
    '';

    # Runs in restored panes: resume that pane's session
    agentsRestore = pkgs.writeShellScript "tmux-agents-restore" ''
      tool=$1
      dir=$(${tmux} show -gqv @agents-state-dir); dir=''${dir:-$HOME/.local/state/tmux-agents}
      me=$(${tmux} display -p -t "$TMUX_PANE" '#{session_name}:#{window_index}.#{pane_index}')
      IFS=$'\t' read -r _ _ sid flags < <(${pkgs.gawk}/bin/awk -F'\t' -v p="$me" -v t="$tool" \
        '$1 == p && $2 == t' "$dir/panes.tsv" 2>/dev/null | tail -1)
      case "$tool" in
        claude)
          if [ -n "''${sid:-}" ]; then exec claude $flags --resume "$sid"; fi
          exec claude --allow-dangerously-skip-permissions --continue ;;
        codex)
          if [ -n "''${sid:-}" ]; then exec codex resume $flags "$sid"; fi
          exec codex resume --last ;;
      esac
    '';
  in {
    programs.tmux.plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-processes '"~claude->${agentsRestore} claude" "~codex->${agentsRestore} codex"'
          set -g @resurrect-hook-post-save-all '${agentsSave}'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];

    # Claude Remote Control for ~/Veria: start sessions on donk from the app
    systemd.user.services.claude-rc = {
      Unit = {
        Description = "Claude Remote Control (~/Veria)";
        After = ["network-online.target"];
        # restarting would end its running sessions
        X-SwitchMethod = "keep-old";
      };
      Service = {
        WorkingDirectory = "%h/Veria";
        # login shell for the full user environment
        ExecStart = "${pkgs.bash}/bin/bash -lc 'exec claude --allow-dangerously-skip-permissions remote-control'";
        Restart = "always";
        RestartSec = 10;
      };
      Install.WantedBy = ["default.target"];
    };

    systemd.user.services.tmux-main = {
      Unit = {
        Description = "tmux session main";
        # restarting would kill everything inside
        X-SwitchMethod = "keep-old";
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "%h";
        ExecStart = "${pkgs.bash}/bin/bash -lc '${config.programs.tmux.package}/bin/tmux new-session -A -d -s main'";
        ExecStop = "${config.programs.tmux.package}/bin/tmux kill-session -t main";
      };
      Install.WantedBy = ["default.target"];
    };
  };

  users.users.${username}.linger = true;

  # 60% charge cap; Quiet on battery and overnight, Balanced 09-21 on AC
  systemd.services.asus-power-profile = {
    description = "Apply ASUS charge limit and time-of-day power profile";
    after = ["asusd.service"];
    wants = ["asusd.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.asusctl pkgs.coreutils];
    script = ''
      asusctl battery limit 60
      asusctl profile set --battery Quiet
      hour=$(date +%-H)
      if [ "$hour" -ge 21 ] || [ "$hour" -lt 9 ]; then
        asusctl profile set --ac Quiet
      else
        asusctl profile set --ac Balanced
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
  systemd.timers.asus-power-profile = {
    wantedBy = ["timers.target"];
    timerConfig.OnCalendar = ["*-*-* 09:00:00" "*-*-* 21:00:00"];
  };
}
