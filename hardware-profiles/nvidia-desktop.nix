{ config, lib, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;

    # Same here: latest has all the explicit sync features needed for Wayland
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    # Fixes flickering in some Electron apps on Nvidia Wayland
    NVD_BACKEND = "direct";
  };
}
