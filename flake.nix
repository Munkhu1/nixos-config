{
  description = "Niri-Multi-User";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    niri-blur = {
          url = "github:niri-wm/niri/pull/3483/head"; # The WIP blur branch
          flake = false;
        };
        niri-flake = {
          url = "github:sodiboo/niri-flake";
          # Override niri-flake's source with our blur fork
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

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangowm = {
      url = "github:mangowm/mango";
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

        inputs.niri-flake.nixosModules.niri
                ({ pkgs, ... }: {
                  nixpkgs.overlays =[ inputs.niri-flake.overlays.niri ];
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
              home.file.".local/bin/swww".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/scripts/swww";
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

          # ==========================================
          # USER 2: niri-noctalia (Noctalia Shell)
          # ==========================================
          home-manager.users.niri-noctalia = { pkgs, ... }: {
            imports =[ noctalia.homeModules.default ];
            home.stateVersion = "23.11";
            programs.noctalia-shell.enable = true;

            dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

            gtk = {
              enable = true;
              theme = {
                name = "Adwaita-dark";
                package = pkgs.gnome-themes-extra;
              };
              gtk4.theme = null;
            };

            home.sessionVariables = {
              EDITOR = "nano";
              VISUAL = "nano";
            };

            home.pointerCursor = {
              gtk.enable = true;
              name = "capitaine-cursors-white";
              package = pkgs.bibata-cursors;
              size = 24;
            };
          };

          # ==========================================
          # USER 3: mango-dank (MangoWM + DMS)
          # ==========================================
          home-manager.users."mango-dank" = { pkgs, ... }: {
            imports = [ dms.homeModules.dank-material-shell ];
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

            xdg.configFile."mango/config.conf".text = ''
              # -- Input & Mouse
              accel_profile=1

              # -- Overview
              ov_tab_mode=1
              enable_hotarea=1
              hotarea_corner=2

              # -- Autostart
              exec-once=systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
              exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
              exec-once=swww-daemon
              exec-once=dms run
              exec-once=systemctl --user start graphical-session.target

              # -- Apps
              bind=SUPER,Return,spawn,kitty
              bind=SUPER,B,spawn,zen
              bind=SUPER,E,spawn,kitty -e yazi
              bind=SUPER,C,spawn,zeditor
              bind=SUPER+CTRL+ALT+SHIFT,W,spawn,libreoffice
              bind=CTRL+SHIFT,Escape,spawn,kitty -e btop
              bind=SUPER+CTRL,V,spawn,pavucontrol
              bind=SUPER+SHIFT,R,reload_config

              # -- Layouts
              bind=SUPER,bracketright,setlayout,scroller
              tagrule=id:1,layout_name:scroller
              tagrule=id:2,layout_name:scroller
              tagrule=id:3,layout_name:scroller
              tagrule=id:4,layout_name:scroller
              tagrule=id:5,layout_name:scroller
              tagrule=id:6,layout_name:scroller
              tagrule=id:7,layout_name:scroller
              tagrule=id:8,layout_name:scroller
              tagrule=id:9,layout_name:scroller

              # -- Window Management
              bind=SUPER,Q,killclient
              bind=SUPER,W,togglefloating
              bind=SUPER,F,togglefullscreen
              bind=SUPER,D,togglemaximizescreen
              bind=SUPER,comma,set_proportion,0.33
              bind=SUPER,period,set_proportion,0.5
              bind=SUPER,slash,set_proportion,0.67
              bind=SUPER,S,spawn_shell,STATE=$(cat /tmp/mango_prop 2>/dev/null); if [ "$STATE" = "0.33" ]; then NEXT=0.67; else NEXT=0.33; fi; echo $NEXT > /tmp/mango_prop; mmsg -s -d set_proportion,$NEXT

              bind=SUPER+SHIFT,S,tagsilent,9
              bind=Alt,Tab,toggleoverview
              bind=SUPER,M,quit

              bind=SUPER,Left,focusdir,left
              bind=SUPER,Right,focusdir,right
              bind=SUPER,Up,focusdir,up
              bind=SUPER,Down,focusdir,down

              bind=SUPER+SHIFT,Left,exchange_client,left
              bind=SUPER+SHIFT,Right,exchange_client,right
              bind=SUPER+SHIFT,Up,exchange_client,up
              bind=SUPER+SHIFT,Down,exchange_client,down

              # -- Workspaces (Tags)
              bind=CTRL+SUPER,Up,viewtoleft
              bind=CTRL+SUPER,Down,viewtoright
              bind=SHIFT+SUPER,Up,tagtoleft
              bind=SHIFT+SUPER,Down,tagtoright
              bind=SUPER+CTRL,Right,viewtoright
              bind=SUPER+CTRL,Left,viewtoleft

              bind=SUPER,1,view,1
              bind=SUPER,2,view,2
              bind=SUPER,3,view,3
              bind=SUPER,4,view,4
              bind=SUPER,5,view,5
              bind=SUPER,6,view,6
              bind=SUPER,7,view,7
              bind=SUPER,8,view,8
              bind=SUPER,9,view,9

              bind=SUPER+SHIFT,1,tag,1
              bind=SUPER+SHIFT,2,tag,2
              bind=SUPER+SHIFT,3,tag,3
              bind=SUPER+SHIFT,4,tag,4
              bind=SUPER+SHIFT,5,tag,5
              bind=SUPER+SHIFT,6,tag,6
              bind=SUPER+SHIFT,7,tag,7
              bind=SUPER+SHIFT,8,tag,8
              bind=SUPER+SHIFT,9,tag,9

              # -- Utilities & Visuals
              bind=SUPER+SHIFT,P,spawn,playerctl play-pause
              bind=SUPER+SHIFT,N,spawn,playerctl next
              bind=SUPER+SHIFT,B,spawn,playerctl previous
              bind=SUPER+SHIFT,C,spawn,hyprpicker -a
              bind=SUPER,L,spawn,loginctl lock-session
              bind=SUPER+SHIFT,L,spawn,systemctl suspend

              bind=NONE,Print,spawn_shell,grim - | wl-copy
              bind=SUPER,Print,spawn_shell,grim -g "$(slurp)" - | swappy -f -

              blur=1
              blur_layer=0
              blur_optimized=1
              blur_params_radius=8
              blur_params_num_passes=2
              tag_animation_direction=0

              source-optional=~/.config/mango/dms/binds.conf
              source-optional=~/.config/mango/dms/outputs.conf
              source-optional=~/.config/mango/dms/layout.conf
              source-optional=~/.config/mango/dms/colors.conf
              source-optional=~/.config/mango/dms/cursor.conf
            '';
          };
        }
      ];
    };
  };
}
