{...}: {
  services.yabai = {
    enable = true;
    enableScriptingAddition = false;

    config = {
      layout = "bsp";
      window_placement = "second_child";
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
      window_gap = 10;
      mouse_modifier = "fn";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
    };

    extraConfig = ''
      # auto-focus window after closing
      yabai -m signal --add event=window_destroyed action="yabai -m query --windows --window &> /dev/null || yabai -m window --focus mouse"

      # auto-balance when switching spaces
      yabai -m signal --add event=space_changed action="yabai -m space --balance"
    '';
  };

  services.skhd = {
    enable = true;
    skhdConfig = ''
      # open terminal (single instance)
      alt - return : open -a "Ghostty"

      # open browser (new instance)
      alt + shift - return : open -na "Google Chrome"

      # open discord
      ctrl + alt - d : open -a "Vesktop"

      # focus window
      alt - h : yabai -m window --focus west
      alt - j : yabai -m window --focus south
      alt - k : yabai -m window --focus north
      alt - l : yabai -m window --focus east

      # swap managed window
      shift + alt - h : yabai -m window --swap west
      shift + alt - j : yabai -m window --swap south
      shift + alt - k : yabai -m window --swap north
      shift + alt - l : yabai -m window --swap east

      # balance size of windows
      shift + alt - 0 : yabai -m space --balance

      # rotate tree
      alt - r : yabai -m space --rotate 90

      # toggle window fullscreen zoom
      alt - f : yabai -m window --toggle zoom-fullscreen

      # float / unfloat window and center on screen
      shift + alt - space : yabai -m window --toggle float --grid 4:4:1:1:2:2

      # change layout of desktop
      ctrl + alt - a : yabai -m space --layout bsp
    '';
  };
}
