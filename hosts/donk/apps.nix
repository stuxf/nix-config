# Apps
{username, ...}: {
  nixpkgs.overlays = [
    # until nixpkgs#551713 lands
    (final: prev: {
      chatgpt = final.callPackage ../../pkgs/chatgpt/package.nix {};
    })
  ];

  home-manager.users.${username} = {pkgs, ...}: {
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
