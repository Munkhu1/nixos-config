{ config, lib, pkgs, inputs, ... }:

let
  # =========================================
  # Custom Derivations
  # =========================================
  pixel-sddm = pkgs.stdenv.mkDerivation {
    pname = "pixel-sddm";
    version = "1.0";
    src = pkgs.fetchFromGitHub {
      owner = "mahaveergurjar";
      repo = "sddm";
      rev = "pixel";
      hash = "sha256-bzA6WUZrXgQDJvOuK5JIcnPJNRhU/8AiKg3jgAeeoBM=";
    };

    nativeBuildInputs =[ pkgs.imagemagick pkgs.matugen pkgs.jq ];

    installPhase = ''
      mkdir -p $out/share/sddm/themes/Pixel
      find . -type f -name "*.qml" -exec sed -i 's/QtGraphicalEffects/Qt5Compat.GraphicalEffects/g' {} +

      cp -r * $out/share/sddm/themes/Pixel/

      magick ${./sddm-wall/wallpaper.jpg} $out/share/sddm/themes/Pixel/my-wallpaper.png
      DOMINANT_HEX=$(magick ${./sddm-wall/wallpaper.jpg} -scale 1x1\! -format "%[hex:u.p{0,0}]" info:)
      matugen color hex "#$DOMINANT_HEX" -j hex > palette.json

      ACCENT=$(jq -r '.colors.dark.primary' palette.json)
      SURFACE=$(jq -r '.colors.dark.surface' palette.json)
      TEXT=$(jq -r '.colors.dark.on_surface' palette.json)

      cat > $out/share/sddm/themes/Pixel/theme.conf.user <<EOF
      [General]
      Background="my-wallpaper.png"
      background="my-wallpaper.png"
      AccentColor="$ACCENT"
      PrimaryColor="$ACCENT"
      BackgroundColor="$SURFACE"
      TextColor="$TEXT"
      EOF
    '';
  };

  inir-quickshell = pkgs.stdenv.mkDerivation {
    pname = "inir-quickshell";
    version = "custom";
    dontUnpack = true;

    nativeBuildInputs = [ pkgs.kdePackages.wrapQtAppsHook ];
    buildInputs = with pkgs.kdePackages;[
      kirigami kirigami-addons qtmultimedia qtdeclarative
      syntax-highlighting plasma-integration qtimageformats
      qtwayland qt5compat qtsvg
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp -a ${pkgs.quickshell}/bin/* $out/bin/
    '';
  };

in
{
  imports =[
      inputs.mangowm.nixosModules.mango
    ] ++ lib.optional (builtins.pathExists /home/niri-dank/.config/1-negro/nixos-config.nix) /home/niri-dank/.config/1-negro/nixos-config.nix;

  # =========================================
  # System Settings (Boot, Network, Time)
  # =========================================
  system.stateVersion = "23.11";

  nix.settings.experimental-features =[ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages =[ "openssl-1.1.1w" ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules =[ "i2c-dev" "i2c-piix4" "nct6775" ];
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
      timeout = 1;
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = true;
      };
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Asia/Ulaanbaatar";

  # =========================================
  # Hardware & Services
  # =========================================
  hardware = {
    graphics.enable = true;
    i2c.enable = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };
    displayManager.sddm = {
      enable = true;
      wayland.enable = false;
      theme = "Pixel";
      package = pkgs.kdePackages.sddm;
      extraPackages = with pkgs.kdePackages;[ qt5compat qtdeclarative qtsvg qtimageformats ];
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    openssh.enable = true;
  };

  security.rtkit.enable = true;

  # =========================================
  # Programs & Environment
  # =========================================
  programs = {
    mango.enable = true;
    niri = {
          enable = true;
          package = pkgs.niri-unstable; # Tell NixOS to use the blur fork
        };
    hyprland.enable = true;
    dconf.enable = true;
    fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting ""
      '';
    };
    starship.enable = true;
    coolercontrol.enable = true;
    nh = {
      enable = true;
      flake = "/etc/nixos";
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 3";
      };
    };
  };

  xdg.portal = {
      enable = true;
      extraPortals =[
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gnome" ];
        };
      };
    };

  environment = {
    pathsToLink = [ "/share/icons" ];
    variables.EDITOR = "zeditor";
    sessionVariables.NIXOS_OZONE_WL = "1";
    sessionVariables.GTK_USE_PORTAL = "1";

    systemPackages = with pkgs;[
      wget git kitty vesktop sublime4 yazi pavucontrol easyeffects starship nautilus
      obs-studio obsidian steam gnome-disk-utility hyprpolkitagent qdirstat
      eza tmux capitaine-cursors zed-editor
      pixel-sddm
      kdePackages.qtwayland kdePackages.qtsvg kdePackages.qtdeclarative kdePackages.qt5compat
      inputs.zen-browser.packages.${pkgs.system}.default

      (pkgs.writeShellScriptBin "jew" ''
        if [ "$1" == "nig" ]; then
            echo "⬇️ Pulling latest changes from GitHub..."
            sudo git -C /etc/nixos pull
            shift
        fi

        echo "Baij bailda psda baas shidne shu..."
        exec nh os switch /etc/nixos -- --impure "$@"
        '')

      # Custom derivation for Pandora
      (rustPlatform.buildRustPackage {
        pname = "pandora";
        version = "git";
        src = fetchFromGitHub {
          owner = "PandorasFox";
          repo = "pandora";
          rev = "release";
          hash = "sha256-wuD8SR33bNC82iNujLztNHnwPZMGycp3aW8JDcypU2Y=";
        };
        cargoHash = "sha256-+EapLZMTZyAKX0cs24EOwaRJwq8J99H78qHYyVXuLD8=";
      })
    ];

    # Niri Configuration
        etc."niri/shared-binds.kdl".text = ''
          recent-windows {
              open-delay-ms 50
              binds {
                  Alt+Tab { next-window; }
              }
          }

          binds {
              // Apps
              Mod+Return { spawn "kitty"; }
              Mod+B { spawn "zen"; }
              Mod+E { spawn "kitty" "-e" "yazi"; }
              Mod+C { spawn "zeditor"; }
              Mod+Ctrl+Alt+Shift+W { spawn "libreoffice"; }
              Ctrl+Shift+Escape { spawn "kitty" "-e" "btop"; }
              Mod+Ctrl+V { spawn "pavucontrol"; }

              // Window Management
              Mod+Q { close-window; }
              Mod+W { toggle-window-floating; }
              Mod+F { fullscreen-window; }
              Mod+S { switch-preset-column-width; }
              Mod+D { maximize-column; }
              Mod+Left  { focus-column-left; }
              Mod+Right { focus-column-right; }
              Mod+Up    { focus-window-up; }
              Mod+Down  { focus-window-down; }
              Mod+Ctrl+Left  { focus-column-left; }
              Mod+Ctrl+Right { focus-column-right; }
              Mod+Shift+Left  { move-column-left; }
              Mod+Shift+Right { move-column-right; }
              Mod+Space { consume-or-expel-window-left; }

              // Workspaces
              Mod+Tab { toggle-overview; }
              Mod+1 { focus-workspace 1; }
              Mod+2 { focus-workspace 2; }
              Mod+3 { focus-workspace 3; }
              Mod+4 { focus-workspace 4; }
              Mod+5 { focus-workspace 5; }
              Mod+6 { focus-workspace 6; }
              Mod+7 { focus-workspace 7; }
              Mod+8 { focus-workspace 8; }
              Mod+9 { focus-workspace 9; }
              Mod+Shift+1 { move-column-to-workspace 1; }
              Mod+Shift+2 { move-column-to-workspace 2; }
              Mod+Shift+3 { move-column-to-workspace 3; }
              Mod+Shift+4 { move-column-to-workspace 4; }
              Mod+Shift+5 { move-column-to-workspace 5; }
              Mod+Shift+6 { move-column-to-workspace 6; }
              Mod+Shift+7 { move-column-to-workspace 7; }
              Mod+Shift+8 { move-column-to-workspace 8; }
              Mod+Shift+9 { move-column-to-workspace 9; }
              Mod+Ctrl+Up   { focus-workspace-up; }
              Mod+Ctrl+Down { focus-workspace-down; }
              Mod+Ctrl+WheelScrollUp   { focus-workspace-up; }
              Mod+Ctrl+WheelScrollDown { focus-workspace-down; }
              Mod+WheelScrollDown { focus-column-right; }
              Mod+WheelScrollUp   { focus-column-left; }
              Mod+Shift+Up   { move-window-to-workspace-up; }
              Mod+Shift+Down { move-window-to-workspace-down; }

              // Utilities
              Mod+Shift+P { spawn "playerctl" "play-pause"; }
              Mod+Shift+N { spawn "playerctl" "next"; }
              Mod+Shift+B { spawn "playerctl" "previous"; }
              Mod+Shift+C { spawn "hyprpicker" "-a"; }
              Mod+L       { spawn "loginctl" "lock-session"; }
              Mod+Shift+L { spawn "systemctl" "suspend"; }

              // Screenshots
              Print       { screenshot; }
              Mod+Print   { screenshot-window; }
          }
        '';
  };

  # =========================================
  # Fonts
  # =========================================
  fonts = {
    packages = with pkgs;[
      nerd-fonts.jetbrains-mono
      material-symbols
      rubik
      dejavu_fonts
      liberation_ttf
      twemoji-color-font
    ];
    fontconfig = {
      enable = true;
      defaultFonts.emoji = [ "Twemoji" ];
    };
  };

  systemd.tmpfiles.rules =[
    "d /var/sddm-background 0777 root root -"
    "d /home/niri-dank/.config/1-negro 0775 niri-dank main - -"
    "f /home/niri-dank/.config/1-negro/nixos-config.nix 0664 niri-dank main - { config, pkgs, ... }:\\n{\\n  environment.systemPackages = with pkgs; [\\n    # Custom packages. Jew.\\n    \\n  ];\\n}\\n"
    "f /home/niri-dank/.config/1-negro/niri-config.kdl 0664 niri-dank main - // Custom niri config. Jew.\\n"
  ];

  # =========================================
  # Users
  # =========================================
  users.groups.main = {};

  users.users."niri-dank" = {
      isNormalUser = true;
      initialPassword = "Minecraft172";
      extraGroups =[ "wheel" "main" "video" "audio" "networkmanager" ];
      shell = pkgs.fish;
      packages = with pkgs;[
        tree
        wl-clipboard
        playerctl
        brightnessctl
        hyprpicker
      ];
    };

  users.users."niri-noctalia" = {
    isNormalUser = true;
    extraGroups =[ "wheel" "main" "video" "audio" "networkmanager" ];
    shell = pkgs.fish;
    packages = with pkgs; [ tree playerctl hyprpicker wl-clipboard brightnessctl ];
  };

  users.users."niri-inir" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "main" "video" "audio" "networkmanager" ];
    shell = pkgs.fish;
    packages = with pkgs;[
      inir-quickshell wl-clipboard cliphist grim slurp matugen fuzzel swww
      (runCommand "awww-alias" {} ''
        mkdir -p $out/bin
        ln -s ${pkgs.swww}/bin/swww $out/bin/awww
        ln -s ${pkgs.swww}/bin/swww-daemon $out/bin/awww-daemon
      '')
      jq bc ripgrep curl rsync libnotify imagemagick playerctl brightnessctl
      libqalculate translate-shell cava swappy tesseract wtype ydotool wlsunset
      gsettings-desktop-schemas procps coreutils findutils glib
      kdePackages.kconfig ddcutil xdg-utils yt-dlp deno mpv swayidle wf-recorder
      socat fprintd kdePackages.kdialog
      (python3.withPackages (ps: with ps; [ evdev pillow ]))
    ];
  };

  users.users."mango-dank" = {
    isNormalUser = true;
    extraGroups =[ "wheel" "main" "video" "audio" "networkmanager" ];
    shell = pkgs.fish;
    packages = with pkgs;[
      matugen swww wl-clipboard cliphist grim slurp jq brightnessctl
      playerctl libnotify swappy cava libqalculate
      inputs.mangowm.packages.${pkgs.system}.default
    ];
  };
}
