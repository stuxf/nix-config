# ASUS Zephyrus G14 GA401QM: Ryzen 9 5900HS (AMD iGPU drives the display),
# RTX 3060 Laptop for offload. Written out instead of nixos-hardware's
# asus-zephyrus-ga401 profile so nothing changes underneath us on update.
{...}: {
  # Default (LTS) kernel: stable's NVIDIA driver doesn't build against the
  # newest one (7.2), and 6.18 fully supports this laptop
  boot.kernelParams = ["amd_pstate=active"];

  # Graphics: AMD iGPU with early KMS; "nvidia" in videoDrivers enables the NVIDIA module
  services.xserver.videoDrivers = ["nvidia" "modesetting"];
  hardware.amdgpu.initrd.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam / 32-bit games
  };

  hardware.nvidia = {
    open = true; # NVIDIA recommends the open modules for Turing and newer
    modesetting.enable = true;
    # Runtime D3: power the dGPU off whenever nothing is using it
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

  # ASUS controls (profiles, charge limit, keyboard); asusd manages power
  # profiles itself, so no TLP / power-profiles-daemon
  services.asusd.enable = true;
  services.tlp.enable = false;
  services.udev.extraHwdb = ''
    evdev:name:*:dmi:bvn*:bvr*:bd*:svnASUS*:pn*:*
     KEYBOARD_KEY_ff31007c=f20    # mic mute button
     KEYBOARD_KEY_ff3100b2=home   # Fn+Left as Home
     KEYBOARD_KEY_ff3100b3=end    # Fn+Right as End
  '';

  hardware.bluetooth.enable = true;
  services.fstrim.enable = true;
  services.fwupd.enable = true; # firmware updates (NVMe, etc.)
  services.smartd.enable = true; # disk health
  services.pcscd.enable = true; # smartcards: YubiKey PIV, OATH and OpenPGP
  zramSwap.enable = true; # compressed RAM swap ahead of the disk swap
}
