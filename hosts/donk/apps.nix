# Desktop apps, YubiKey and everyday CLI tools
{username, ...}: {
  nixpkgs.overlays = [
    # ChatGPT desktop (Linux preview), until nixpkgs#551713 lands
    (final: prev: {
      chatgpt = final.callPackage ../../pkgs/chatgpt/package.nix {};
    })
  ];

  home-manager.users.${username} = {pkgs, ...}: {
    # YubiKey: reach it through pcscd (shared with ykman / Yubico Authenticator)
    # instead of gpg's own driver, which would lock the others out
    programs.gpg = {
      enable = true;
      scdaemonSettings.disable-ccid = true;
    };
    services.gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-gnome3;
    };

    # Lets the ChatGPT app's Chrome plugin talk to Chrome (see pkgs/chatgpt)
    xdg.configFile."google-chrome/NativeMessagingHosts/com.openai.codexextension.json".source = "${pkgs.chatgpt}/share/chatgpt/native-messaging-hosts/com.openai.codexextension.json";

    home.packages = with pkgs; [
      # Chat and media
      vesktop
      spotify
      telegram-desktop
      signal-desktop
      notion-app-enhanced
      chatgpt # pkgs/chatgpt

      # Office
      libreoffice
      hunspell

      # Hobby / school
      pinta
      godot
      SDL2
      SDL2.dev
      sdl3
      sdl3.dev
      nmap
      mprocs

      # YubiKey
      yubikey-manager

      # System inspection
      iotop
      iftop
      strace
      lsof
      sysstat
      lm_sensors
      ethtool
      pciutils
      usbutils

      # Misc CLI (eza backs the shared ls aliases; comma is `, <cmd>`)
      eza
      ripgrep
      fd
      comma
      cowsay
      pokemonsay
      krabby
      fastfetch
      nerdfetch
      dust
      hyperfine
      tealdeer
      fx
      file
      which
      tree
      zip
      unzip
      xz
      p7zip
      imagemagick
      wl-clipboard
    ];
  };
}
