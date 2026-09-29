# ASUS Zephyrus G14 GA401QM (5900HS + RTX 3060, PRIME offload)
{...}: {
  # LTS kernel: stable's NVIDIA driver doesn't build on the newest
  boot.kernelParams = ["amd_pstate=active"];

  services.xserver.videoDrivers = ["nvidia" "modesetting"];
  hardware.amdgpu.initrd.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam / 32-bit games
  };

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    # power the dGPU off when idle
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    # nvidia-powerd keeps a client open on the GPU and fights RTD3
    dynamicBoost.enable = false;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # `nvidia-offload <app>`
      };
      amdgpuBusId = "PCI:4:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # asusd manages power profiles, so no TLP
  services.asusd.enable = true;
  services.tlp.enable = false;
  services.udev.extraHwdb = ''
    evdev:name:*:dmi:bvn*:bvr*:bd*:svnASUS*:pn*:*
     KEYBOARD_KEY_ff31007c=f20    # mic mute button
     KEYBOARD_KEY_ff3100b2=home   # Fn+Left as Home
     KEYBOARD_KEY_ff3100b3=end    # Fn+Right as End
  '';

  # Intel AX200: drops packets under load in the default balanced power
  # scheme, and stalls on Wi-Fi 6 with this (Google) router
  boot.extraModprobeConfig = ''
    options iwlmvm power_scheme=1
    options iwlwifi disable_11ax=1
  '';

  hardware.bluetooth.enable = true;
  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.smartd.enable = true;
  services.pcscd.enable = true; # YubiKey
  zramSwap.enable = true;
}
