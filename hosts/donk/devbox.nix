# Settings for running donk as an always-on remote devbox
{
  pkgs,
  username,
  ...
}: {
  # Reach the box over the tailnet only; `tailscale up` once to log in.
  # --ssh enables Tailscale SSH (auth via tailnet identity, no keys to manage)
  services.tailscale = {
    enable = true;
    extraSetFlags = ["--ssh"];
  };
  # Services listening on the tailnet (e.g. Steam Remote Play) are reachable
  # from your own devices but stay blocked on other networks
  networking.firewall.trustedInterfaces = ["tailscale0"];

  # Never sleep: ignore the lid and disable the sleep targets entirely
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

  # Stay reachable: keep Wi-Fi out of power-save and never give up reconnecting
  networking.networkmanager.wifi.powersave = false;
  networking.networkmanager.settings.main.autoconnect-retries-default = 0;

  # Reboot automatically if the kernel hangs (AMD SP5100 TCO watchdog)
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "30s";
    RebootWatchdogSec = "10min";
  };

  # Start user services (e.g. long-running agent sessions) at boot
  # and keep them running without an active login
  users.users.${username}.linger = true;

  # ASUS power settings, applied at boot and whenever the schedule flips:
  # - cap the charge at 80% (always plugged in)
  # - Quiet on battery; on AC, Balanced 09:00-21:00 and Quiet (fans off) overnight,
  #   since it sits next to the bed
  systemd.services.asus-power-profile = {
    description = "Apply ASUS charge limit and time-of-day power profile";
    after = ["asusd.service"];
    wants = ["asusd.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.asusctl pkgs.coreutils];
    script = ''
      asusctl battery limit 80
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
      # asusd may not be answering on D-Bus yet at boot
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
  systemd.timers.asus-power-profile = {
    wantedBy = ["timers.target"];
    timerConfig.OnCalendar = ["*-*-* 09:00:00" "*-*-* 21:00:00"];
  };
}
