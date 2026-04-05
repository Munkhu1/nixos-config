{ config, lib, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true; # turn off dgpu when not gaming
    open = true;
    nvidiaSettings = true;

    # 'latest' is heavily recommended for Wayland gaming over 'beta' right now
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Bus IDs are intentionally omitted here.
      # They are dynamically detected and injected by install.sh
    };
  };
}
