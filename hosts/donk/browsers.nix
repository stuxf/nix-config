# Browsers and default apps: Chrome (main, with enforced policies), Firefox
# (backup), zathura for PDFs, and which app opens which kind of file or link
{username, ...}: {
  # Chrome only reads enforced policies from /etc/opt/chrome, so these live on
  # the system side. They apply to every Chrome profile
  programs.chromium = {
    enable = true;
    extensions = [
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "fcoeoabgfenejglbffodgkkbkcdhcgfn" # Claude
      "hehggadaopoacecdllhhajmbjkdcmajg" # ChatGPT
    ];
    extraOpts.PasswordManagerEnabled = false; # passwords live in Bitwarden
  };

  home-manager.users.${username} = {config, ...}: let
    lock-false = {
      Value = false;
      Status = "locked";
    };
    lock-true = {
      Value = true;
      Status = "locked";
    };
    lock-empty-string = {
      Value = "";
      Status = "locked";
    };
    chrome = "google-chrome.desktop";
    images = "imv.desktop";
  in {
    programs.google-chrome.enable = true;
    home.sessionVariables.BROWSER = "google-chrome-stable";

    programs.firefox = {
      enable = true;
      configPath = "${config.xdg.configHome}/mozilla/firefox";

      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DontCheckDefaultBrowser = true;
        DisablePocket = true;
        SearchBar = "unified";

        Preferences = {
          # Privacy settings
          "extensions.pocket.enabled" = lock-false;
          "browser.newtabpage.pinned" = lock-empty-string;
          "browser.topsites.contile.enabled" = lock-false;
          "browser.newtabpage.activity-stream.showSponsored" = lock-false;
          "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
          "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = lock-false;
          "browser.newtabpage.activity-stream.feeds.topsites" = lock-false;
        };

        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
          };
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
            installation_mode = "force_installed";
          };
        };
      };
    };

    programs.zathura.enable = true;

    xdg.mimeApps = {
      enable = true;
      defaultApplications =
        {
          # Web
          "text/html" = chrome;
          "application/xhtml+xml" = chrome;
          "x-scheme-handler/http" = chrome;
          "x-scheme-handler/https" = chrome;
          "x-scheme-handler/about" = chrome;
          "x-scheme-handler/unknown" = chrome;
          "x-scheme-handler/mailto" = chrome;
          "x-scheme-handler/webcal" = chrome;

          # Documents
          "application/pdf" = "org.pwmt.zathura.desktop";
          "image/vnd.djvu+multipage" = "org.pwmt.zathura-djvu.desktop";

          # App links
          "x-scheme-handler/discord" = "vesktop.desktop";
          "x-scheme-handler/sgnl" = "signal.desktop";
          "x-scheme-handler/signalcaptcha" = "signal.desktop";
          "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
          "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
          "x-scheme-handler/notion" = "notion-app-enhanced.desktop";
          "x-scheme-handler/codex" = "chatgpt.desktop";
          # written by Claude Code itself into ~/.local/share/applications
          "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
        }
        // builtins.listToAttrs (map (t: {
            name = "image/${t}";
            value = images;
          }) [
            "jpeg"
            "png"
            "gif"
            "webp"
            "tiff"
            "bmp"
            "svg+xml"
            "avif"
            "heic"
            "jxl"
            "x-tga"
            "x-exr"
            "x-qoi"
            "vnd.microsoft.icon"
            "x-portable-anymap"
          ]);
    };
  };
}
