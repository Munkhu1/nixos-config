{ config, pkgs, ... }:

{
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    extraPackages = with pkgs;[
      amdvlk
      rocmPackages.clr.icd # OpenCL support
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };
  programs.coolercontrol.enable = true;
}
