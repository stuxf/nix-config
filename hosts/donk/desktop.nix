# Desktop: sway on the AMD iGPU with greetd, waybar, drop-down menus,
# notifications, lock/idle, fonts, Catppuccin, terminals
{
  pkgs,
  inputs,
  username,
  ...
}: {
  imports = [inputs.catppuccin.nixosModules.catppuccin];

  # Keep sway on the AMD iGPU (internal panel + HDMI) so the NVIDIA card can
  # stay powered down. The by-path name has colons, which WLR_DRM_DEVICES can't take
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:04:00.0", SYMLINK+="dri/amd-igpu"
  '';

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    # sway refuses to start while the NVIDIA module is loaded
    extraOptions = ["--unsupported-gpu"];
    extraSessionCommands = "export WLR_DRM_DEVICES=/dev/dri/amd-igpu";
  };

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
  };

  # Keyring unlocked by the login password (Chrome and apps store secrets there)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  xdg.portal = {
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default = ["wlr" "gtk"];
  };

  # Things GNOME used to provide
  services.gvfs.enable = true; # trash, drives and network shares in Nautilus
  services.udisks2.enable = true;
  services.blueman.enable = true;
  programs.dconf.enable = true;

  # Catppuccin for the console and system-level bits
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
    # Saves to ~/Pictures/Screenshots and copies to the clipboard; extra args go to grim
    shot = pkgs.writeShellScript "screenshot" ''
      dir=~/Pictures/Screenshots
      mkdir -p "$dir"
      ${pkgs.grim}/bin/grim "$@" - | tee "$dir/$(date +%F_%H-%M-%S).png" | ${pkgs.wl-clipboard}/bin/wl-copy
    '';
  in {
    imports = [inputs.catppuccin.homeModules.catppuccin];

    wayland.windowManager.sway = {
      enable = true;
      # Use the NixOS sway wrapper (GPU pinning, --unsupported-gpu), not a second copy
      package = null;
      config = {
        modifier = "Mod4";
        terminal = "foot";
        menu = "fuzzel";
        bars = []; # waybar instead of swaybar
        defaultWorkspace = "workspace number 1"; # otherwise the sorted keybindings make it 10
        fonts = {
          names = ["JetBrainsMonoNL Nerd Font Propo"];
          size = 10.0;
        };
        # Thin borders, no title bars; Catppuccin colors ($pink etc. come from
        # the catppuccin sway module)
        window = {
          border = 2;
          titlebar = false;
        };
        gaps.inner = 10; # always, even with a single window; matches the Mac (yabai window_gap)
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
        startup = [{command = "${pkgs.autotiling}/bin/autotiling";}]; # dynamic tiling, like pop-shell
        output = {
          "eDP-1".mode = "1920x1080@59.990Hz"; # 60 Hz to save power (144 Hz: 143.981Hz)
          "*".bg = "${./wallpaper.png} fill";
        };
        input."type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
        };
        keybindings = lib.mkOptionDefault {
          "--release Super_L" = "exec fuzzel"; # tap Super to open the launcher, like GNOME
          "Mod4+q" = "kill"; # close, like GNOME (Super+Shift+Q still works)
          "Mod1+Tab" = "exec swayr next-window all-workspaces"; # cycle, most recent first
          "Mod1+Shift+Tab" = "exec swayr prev-window all-workspaces";
          "Mod4+Tab" = "exec swayr switch-window"; # searchable list of all windows
          "Print" = "exec ${shot} -g \"$(${pkgs.slurp}/bin/slurp)\""; # area
          "Shift+Print" = "exec ${shot}"; # full screen
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

    # Standard companions: waybar (stock default config), swayosd pop-ups for
    # volume/brightness, fuzzel launcher, mako notifications, tray applets
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
          interval = 1; # redraw every second for the seconds
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 muted";
          format-icons.default = ["󰕿" "󰖀" "󰕾"];
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; # scroll: volume
          on-click-right = "pavucontrol"; # devices and per-app volume
        };
        idle_inhibitor = {
          # Coffee cup: keep the screen on (no lock / screen-off) while active
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
          on-click = "bzmenu --launcher custom --launcher-command 'fuzzel --dmenu --anchor top-right --x-margin 8 --y-margin 4 --width 34 --lines 12'"; # devices, pairing, power
          on-click-right = "blueman-manager";
        };
        network = {
          format-wifi = "󰖩"; # name shows on hover
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          format-ethernet = "󰈀";
          format-disconnected = "󰖪";
          on-click = "networkmanager_dmenu"; # pick a network (menu from the config below)
        };
        backlight = {
          format = "󰃟 {percent}%"; # scroll to adjust
          on-scroll-up = "swayosd-client --brightness raise";
          on-scroll-down = "swayosd-client --brightness lower";
        };
        "custom/profile" = {
          # Current ASUS power profile; click cycles Quiet -> Balanced -> Performance
          exec = "asusctl profile get | sed -n 's/^Active profile: //p'";
          interval = 5;
          format = "󰾅 {}";
          on-click = "asusctl profile next";
        };
        "custom/notification" = {
          # Bell: notification count / Do Not Disturb
          exec = "swaync-client -swb";
          return-type = "json";
          format = "{icon}";
          format-icons = {
            none = "󰂚";
            notification = "󱅫";
            dnd-none = "󰂛";
            dnd-notification = "󰂛";
          };
          on-click = "swaync-client -t -sw"; # notification history
          on-click-right = "swaync-client -d -sw"; # toggle Do Not Disturb
          tooltip = false;
        };
        battery = {
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-icons = ["󰁺" "󰁼" "󰁾" "󰂀" "󰁹"];
        };
      };
      # Catppuccin colors (@base, @text, @accent, ...) are imported by the catppuccin module
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
    # Notifications (bell in the bar opens a narrow history list)
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
      # Alt+Tab window switching
      enable = true;
      systemd.enable = true;
      settings.menu = {
        executable = lib.getExe config.programs.fuzzel.package;
        args = ["--dmenu" "--prompt={prompt}"];
      };
      # Plain text entries; the defaults carry wofi-only "img:...:text:" markup
      # Presses within 1 s keep walking the list instead of flipping between two
      settings.focus.lockin_delay = 1000;
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
    services.polkit-gnome.enable = true; # password prompts for admin actions

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

    # Nautilus: files, imv: images, pavucontrol: audio devices and levels
    home.packages = with pkgs; [
      nautilus
      imv
      pavucontrol
      adwaita-icon-theme
      networkmanager_dmenu
      bzmenu
      # fonts
      inter
      liberation_ttf # metric-compatible Arial/Times/Courier for documents and sites
      nerd-fonts.jetbrains-mono
      noto-fonts-color-emoji
    ];

    # Catppuccin cursor; Adwaita's icons stay installed for GTK apps' symbolic icons
    catppuccin.cursors.enable = true;
    catppuccin.cursors.accent = "dark"; # neutral instead of the pink accent
    home.pointerCursor = {
      enable = true;
      size = 24;
      gtk.enable = true;
      sway.enable = true;
    };

    # Fonts (packages above): Inter for UI, JetBrains Mono for code, Liberation for compatibility
    fonts.fontconfig = {
      enable = true;
      # Smooth, lightly hinted, subpixel (RGB) text, as GNOME had it
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
    # GTK/libadwaita apps take their UI font from here
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

    # Terminals: foot is the default (Super+Enter), Ghostty stays installed
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
