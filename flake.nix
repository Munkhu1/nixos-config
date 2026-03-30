{
  description = "Niri-Multi-User";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager"; 
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell for niri-dank
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia Shell for niri-noctalia
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, dms, noctalia, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      specialArgs = { inherit inputs; }; 
      
      modules =[
        ./hardware-configuration.nix
        ./configuration.nix
        
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          
          # ==========================================
          # USER 1: niri-dank (Dank Material Shell)
          # ==========================================
          home-manager.users.niri-dank = { pkgs, ... }: {
            imports =[
              dms.homeModules.dank-material-shell
            ];

            home.stateVersion = "23.11"; 
            programs.dank-material-shell.enable = true;

            home.packages = [
              inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
            ];
          };

          # ==========================================
          # USER 2: niri-noctalia (Noctalia Shell)
          # ==========================================
          home-manager.users.niri-noctalia = { pkgs, ... }: {
            imports =[
              noctalia.homeModules.default
            ];

            home.stateVersion = "23.11"; 
            programs.noctalia-shell.enable = true;

            home.packages =[
              inputs.zen-browser.packages."${pkgs.system}".default
            ];
	           dconf.settings = {
              "org/gnome/desktop/interface" = {
                color-scheme = "prefer-dark";
              };
            };

            # 2. Forces older GTK3 apps to use the Dark Theme
            gtk = {
              enable = true;
              theme = {
                name = "Adwaita-dark";
                package = pkgs.gnome-themes-extra;
              };
              gtk4.theme = null;
            };
          home.sessionVariables = {
              EDITOR = "nano";    # Or use "subl -w" if you want Sublime Text to open!
              VISUAL = "nano";
            };

            # ====== NEW: FIX THE CURSOR ======
            home.pointerCursor = {
              gtk.enable = true;
              name = "Bibata-Modern-Classic";
              package = pkgs.bibata-cursors;
              size = 24;          # 24 is the standard small/medium size. (Default Wayland is often 32+)
            };
          };

        }
      ];
    };
  };
}

