# sway desktop
{
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [inputs.catppuccin.nixosModules.catppuccin];

  # Pin sway to the AMD iGPU so the NVIDIA card can sleep (WLR_DRM_DEVICES
  # can't take the by-path name's colons)
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:04:00.0", SYMLINK+="dri/amd-igpu"
  '';

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    # needed while the NVIDIA module is loaded
    extraOptions = ["--unsupported-gpu"];
    extraSessionCommands = "export WLR_DRM_DEVICES=/dev/dri/amd-igpu";
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.greetd = {
    enable = true;
    settings = {
      # Autologin once per boot so apps come back after a remote reboot
      initial_session = {
        user = username;
        command = "sway";
      };
      default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
    };
  };

  # Moonlight host; pair at https://donk:47990
  services.sunshine = {
    enable = true;
    autoStart = true;
    settings = {
      capture = "wlr";
      encoder = "vaapi";
      adapter_name = "/dev/dri/by-path/pci-0000:04:00.0-render";
      # tailnet counts as wan
      origin_web_ui_allowed = "wan";
      csrf_allowed_origins = "https://donk:47990";
    };
  };

  # Keyring password is empty (set in seahorse) so autologin unlocks it
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  xdg.portal = {
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default = ["wlr" "gtk"];
  };

  # Things GNOME used to provide
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.blueman.enable = true;
  programs.dconf.enable = true;

  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "pink";
  };

  home-manager.users.${username} = {
    lib,
    pkgs,
    config,
    ...
  }: let
    # To ~/Pictures/Screenshots and the clipboard
    shot = pkgs.writeShellScript "screenshot" ''
      dir=~/Pictures/Screenshots
      mkdir -p "$dir"
      ${pkgs.grim}/bin/grim "$@" - | tee "$dir/$(date +%F_%H-%M-%S).png" | ${pkgs.wl-clipboard}/bin/wl-copy
    '';
    # Attach to tmux "main" unless a foot window already is
    tmux = "${config.programs.tmux.package}/bin/tmux";
    term = pkgs.writeShellScript "term" ''
      if ${tmux} list-clients -t main -F '#{client_termname}' 2>/dev/null | grep -q '^foot'; then
        exec foot
      fi
      exec foot sh -c '${tmux} new-session -A -s main; exec fish'
    '';
  in {
    imports = [inputs.catppuccin.homeModules.catppuccin];

    wayland.windowManager.sway = {
      enable = true;
      # use the NixOS wrapper above
      package = null;
      config = {
        modifier = "Mod4";
        terminal = "${term}";
        menu = "fuzzel";
        bars = [];
        defaultWorkspace = "workspace number 1";
        fonts = {
          names = ["JetBrainsMonoNL Nerd Font Propo"];
          size = 10.0;
        };
        window = {
          border = 2;
          titlebar = false;
        };
        gaps.inner = 10;
        floating.titlebar = false;
        colors = let
          c = border: {
            inherit border;
            background = "$base";
            text = "$text";
            indicator = border;
            childBorder = border;
          };
        in {
          focused = c "$pink";
          focusedInactive = c "$surface1";
          unfocused = c "$surface0";
          urgent = c "$peach";
        };
        startup = [
          # lock first: autologin
          {command = "${lib.getExe config.programs.swaylock.package} -f";}
          {command = "${pkgs.autotiling}/bin/autotiling";}
          {command = "${term}";}
          {command = "google-chrome-stable --profile-directory='Profile 1'";}
          {command = "chatgpt";}
        ];
        assigns = {
          "2" = [{class = "^Chatgpt$";} {app_id = "(?i)^chatgpt$";}];
          "3" = [{app_id = "^google-chrome$";} {class = "^Google-chrome$";}];
        };
        output = {
          "eDP-1".mode = "1920x1080@59.990Hz"; # 60 Hz saves power
          "*".bg = "${./wallpaper.png} fill";
        };
        # Moonlight on macOS doesn't send ⌘: right Option is Super when streaming
        input."48879:57005:Keyboard_passthrough".xkb_options = "altwin:swap_ralt_rwin";
        input."type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
        };
        keybindings = lib.mkOptionDefault {
          "--release Super_L" = "exec fuzzel";
          "--release Super_R" = "exec fuzzel";
          "Mod4+q" = "kill";
          "Mod1+Tab" = "exec swayr next-window all-workspaces";
          "Mod1+Shift+Tab" = "exec swayr prev-window all-workspaces";
          "Mod4+Tab" = "exec swayr switch-window";
          "Print" = "exec ${shot} -g \"$(${pkgs.slurp}/bin/slurp)\"";
          "Shift+Print" = "exec ${shot}";
          "XF86AudioMicMute" = "exec swayosd-client --input-volume mute-toggle";
          "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
          "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
          "XF86AudioRaiseVolume" = "exec swayosd-client --output-volume raise";
          "XF86AudioLowerVolume" = "exec swayosd-client --output-volume lower";
          "XF86AudioMute" = "exec swayosd-client --output-volume mute-toggle";
          "XF86MonBrightnessUp" = "exec swayosd-client --brightness raise";
          "XF86MonBrightnessDown" = "exec swayosd-client --brightness lower";
        };
      };
      extraConfig = ''
        bindgesture swipe:3:right workspace prev_on_output
        bindgesture swipe:3:left workspace next_on_output
      '';
    };

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings.main = {
        height = 30;
        spacing = 4;
        modules-left = ["sway/workspaces" "sway/mode"];
        modules-center = ["clock"];
        modules-right = ["tray" "idle_inhibitor" "network" "bluetooth" "backlight" "pulseaudio" "custom/profile" "battery" "custom/notification"];
        clock = {
          format = "{:%a %b %d  %H:%M:%S}";
          interval = 1;
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 muted";
          format-icons.default = ["󰕿" "󰖀" "󰕾"];
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right = "pavucontrol";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
        };
        bluetooth = {
          format = "󰂯";
          format-disabled = "󰂲";
          format-off = "󰂲";
          format-connected = "󰂱 {num_connections}";
          tooltip-format-connected = "{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
          on-click = "bzmenu --launcher custom --launcher-command 'fuzzel --dmenu --anchor top-right --x-margin 8 --y-margin 4 --width 34 --lines 12'";
          on-click-right = "blueman-manager";
        };
        network = {
          format-wifi = "󰖩";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          format-ethernet = "󰈀";
          format-disconnected = "󰖪";
          on-click = "networkmanager_dmenu";
        };
        backlight = {
          format = "󰃟 {percent}%";
          on-scroll-up = "swayosd-client --brightness raise";
          on-scroll-down = "swayosd-client --brightness lower";
        };
        "custom/profile" = {
          # ASUS power profile; click to cycle
          exec = "asusctl profile get | sed -n 's/^Active profile: //p'";
          interval = 5;
          format = "󰾅 {}";
          on-click = "asusctl profile next";
        };
        "custom/notification" = {
          exec = "swaync-client -swb";
          return-type = "json";
          format = "{icon}";
          format-icons = {
            none = "󰂚";
            notification = "󱅫";
            dnd-none = "󰂛";
            dnd-notification = "󰂛";
          };
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw"; # Do Not Disturb
          tooltip = false;
        };
        battery = {
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-icons = ["󰁺" "󰁼" "󰁾" "󰂀" "󰁹"];
        };
      };
      # @base, @accent etc. come from catppuccin
      style = ''
        * { font-family: "JetBrainsMonoNL Nerd Font Propo"; font-size: 13px; min-height: 0; }
        window#waybar { background: alpha(@base, 0.9); color: @text; }
        #workspaces, #clock, #tray, #idle_inhibitor, #network, #bluetooth, #backlight, #pulseaudio, #custom-profile, #battery, #custom-notification {
          background: @surface0; border-radius: 8px; padding: 0 10px; margin: 4px 0;
        }
        #workspaces { padding: 0 4px; margin-left: 4px; }
        #workspaces button { color: @subtext0; padding: 0 6px; border-radius: 6px; }
        #workspaces button.focused { background: @accent; color: @base; }
        #workspaces button.urgent { background: @peach; color: @base; }
        #custom-notification { margin-right: 4px; }
        #battery.warning { color: @yellow; }
        #battery.critical { color: @red; }
      '';
    };
    services.swayosd.enable = true;
    programs.fuzzel = {
      enable = true;
      settings.main.font = "JetBrainsMonoNL Nerd Font Propo:size=12";
    };
    services.swaync = {
      enable = true;
      settings = {
        transition-time = 100;
        control-center-width = 380;
        widgets = ["title" "dnd" "mpris" "notifications"];
        widget-config.mpris.autohide = true;
      };
    };
    programs.swayr = {
      # Alt+Tab
      enable = true;
      systemd.enable = true;
      settings.menu = {
        executable = lib.getExe config.programs.fuzzel.package;
        args = ["--dmenu" "--prompt={prompt}"];
      };
      # repeated presses keep walking the list
      settings.focus.lockin_delay = 1000;
      # defaults use wofi-only markup
      settings.format = {
        window_format = "{app_name}  —  {title}  ({workspace_name})";
        workspace_format = "Workspace {name}";
        container_format = "{layout}";
        html_escape = false;
      };
    };
    xdg.configFile."networkmanager-dmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = fuzzel --dmenu --anchor top-right --x-margin 8 --y-margin 4 --width 34 --lines 12
      compact = True
      wifi_chars = ▂▄▆█
    '';
    services.polkit-gnome.enable = true;

    programs.swaylock.enable = true;
    services.swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 600;
          command = "${lib.getExe config.programs.swaylock.package} -f";
        }
        {
          timeout = 900;
          command = "${pkgs.sway}/bin/swaymsg 'output * power off'";
          resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * power on'";
        }
      ];
    };

    home.packages = with pkgs; [
      nautilus
      imv
      pavucontrol
      adwaita-icon-theme
      networkmanager_dmenu
      bzmenu
      # fonts
      inter
      liberation_ttf
      nerd-fonts.jetbrains-mono
      noto-fonts-color-emoji
    ];

    catppuccin.cursors.enable = true;
    catppuccin.cursors.accent = "dark";
    home.pointerCursor = {
      enable = true;
      size = 24;
      gtk.enable = true;
      sway.enable = true;
    };

    fonts.fontconfig = {
      enable = true;
      antialiasing = true;
      hinting = "slight";
      subpixelRendering = "rgb";
      defaultFonts = {
        sansSerif = ["Inter"];
        serif = ["Liberation Serif"];
        monospace = ["JetBrainsMonoNL Nerd Font Mono"];
        emoji = ["Noto Color Emoji"];
      };
    };
    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      font-name = "Inter 11";
      document-font-name = "Inter 11";
      monospace-font-name = "JetBrainsMonoNL Nerd Font Mono 11";
    };

    gtk.enable = true;
    catppuccin = {
      enable = true;
      autoEnable = true;
      flavor = "mocha";
      accent = "pink";
    };

    programs.foot = {
      enable = true;
      settings.main.font = "JetBrainsMonoNL Nerd Font:size=11";
    };
    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;
      settings.font-family = "JetBrainsMono Nerd Font";
    };
  };
}
