{...}: {
  # AeroSpace - i3-like tiling window manager
  # Minimal configuration - start small and build up!
  # Docs: https://nikitabobko.github.io/AeroSpace/guide

  services.aerospace = {
    enable = true;

    settings = {
      # Use tiles layout (not accordion!)
      default-root-container-layout = "tiles";

      # Smart window arrangement (closest to dwindle behavior)
      # Wide monitors: windows split left/right
      # Tall monitors: windows split top/bottom
      default-root-container-orientation = "auto";

      # Mouse follows focus (like Pop OS / Hyprland)
      on-focused-monitor-changed = ["move-mouse monitor-lazy-center"];

      # Gaps around windows
      gaps = {
        inner.horizontal = 10;
        inner.vertical = 10;
        outer.left = 10;
        outer.bottom = 10;
        outer.top = 10;
        outer.right = 10;
      };

      mode.main.binding = {
        # Focus windows (vim keys)
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        # Move windows around
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        # Resize windows
        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        # Fullscreen (like Pop OS super+f)
        alt-shift-m = "fullscreen";

        # Switch workspaces
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";

        # Quick switch to last workspace (super useful!)
        alt-tab = "workspace-back-and-forth";

        # Send window to workspace
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";

        # Send window to workspace AND follow it
        alt-ctrl-1 = ["move-node-to-workspace 1" "workspace 1"];
        alt-ctrl-2 = ["move-node-to-workspace 2" "workspace 2"];
        alt-ctrl-3 = ["move-node-to-workspace 3" "workspace 3"];
        alt-ctrl-4 = ["move-node-to-workspace 4" "workspace 4"];
        alt-ctrl-5 = ["move-node-to-workspace 5" "workspace 5"];

        # Toggle floating
        alt-shift-f = "layout floating tiling";

        # Service mode for advanced operations
        alt-shift-semicolon = "mode service";
      };

      # Service mode - for less common operations
      mode.service.binding = {
        # Return to normal mode
        esc = "mode main";

        # Reset layout if you mess it up
        r = ["flatten-workspace-tree" "mode main"];

        # Join windows (manual container control, advanced)
        h = ["join-with left" "mode main"];
        j = ["join-with down" "mode main"];
        k = ["join-with up" "mode main"];
        l = ["join-with right" "mode main"];

        # Close all windows except current
        backspace = ["close-all-windows-but-current" "mode main"];

        # Toggle layout orientation
        alt-slash = ["layout tiles horizontal vertical" "mode main"];
      };
    };
  };
}
