{
  description = "Niri-Multi-User";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    niri-blur = {
          url = "github:niri-wm/niri/pull/3483/head";
          flake = false;
        };
        niri-flake = {
          url = "github:sodiboo/niri-flake";
          inputs.niri-unstable.follows = "niri-blur";
          inputs.nixpkgs.follows = "nixpkgs";
        };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs = { self, nixpkgs, home-manager, dms, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };

      modules =[
        (if builtins.pathExists /mnt/etc/nixos/hardware-configuration.nix
          then /mnt/etc/nixos/hardware-configuration.nix
          else /etc/nixos/hardware-configuration.nix)
        ./configuration.nix

        {
          nixpkgs.overlays =[ inputs.nix-cachyos-kernel.overlays.pinned ];
        }
        inputs.niri-flake.nixosModules.niri
                ({ pkgs, ... }: {
                  nixpkgs.overlays =[
                    inputs.niri-flake.overlays.niri
                    inputs.nix-cachyos-kernel.overlays.pinned
                  ];
                })

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.backupFileExtension = "backup";

          # ==========================================
          # USER 1: niri-dank (Dank Material Shell)
          # ==========================================
          home-manager.users.niri-dank = { config, pkgs, lib, ... }: {
            imports =[ dms.homeModules.dank-material-shell ];
            home.stateVersion = "23.11";
            programs.dank-material-shell.enable = true;

            dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

            gtk = {
              enable = true;
              theme = {
                name = "adw-gtk3-dark";
                package = pkgs.adw-gtk3;
              };
              gtk4.theme = null;
            };

            # wallpaper script symlink
            home.sessionPath =[ "$HOME/.local/bin" ];
            home.file.".local/bin/matugen".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/scripts/matugen";

            # ====================================================================================
            # LIVE-EDITABLE DOTFILES (Mutable Symlinks straight to /etc/nixos/dotfiles)
            # ====================================================================================

            xdg.configFile."niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/niri";
            xdg.configFile."starship.toml".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/starship.toml";
            xdg.configFile."yazi".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/yazi";
            xdg.configFile."zed".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/zed";
            xdg.configFile."kitty".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/kitty";

          };
        }
      ];
    };
  };
}
