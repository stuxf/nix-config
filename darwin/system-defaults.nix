{...}: {
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      minimize-to-application = true;
      launchanim = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
      FXEnableExtensionChangeWarning = false;
    };

    NSGlobalDomain = {
      # Fast key repeat for vim users
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;

      # Expanded dialogs
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;

      # Disable auto-correct
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      # Trackpad tap to click
      "com.apple.mouse.tapBehavior" = 1;
    };

    trackpad = {
      Clicking = true;
    };

    screencapture = {
      location = "~/Pictures/Screenshots";
      disable-shadow = true;
    };
  };

  # Create Screenshots directory
  system.activationScripts.postActivation.text = ''
    mkdir -p ~/Pictures/Screenshots
  '';
}
