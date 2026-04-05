{ config, lib, pkgs, inputs, ... }:

let
  # =========================================
  # Custom Derivations
  # =========================================
  elegant-grub-theme = pkgs.stdenv.mkDerivation {
    pname = "elegant-grub-theme";
    version = "git";

    src = pkgs.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "Elegant-grub2-themes";
      rev = "main";
      hash = "sha256-fbZLWHxnLBrqBrS2MnM2G08HgEM2dmZvitiCERie0Cc=";
    };

    nativeBuildInputs =[ pkgs.bash ];

    postPatch = ''
      # (Optional) Uncomment the line below to use custom SDDM wp
      # cp ${./sddm-wall/wallpaper.jpg} background.jpg
    '';

    buildPhase = ''
      patchShebangs .
      # Customize your options here.
      # -t [forest|mojave|mountain|wave]
      # -p [window|float|sharp|blur]
      # -i[left|right]
      # -c [dark|light]
      # -s[1080p|2k|4k]
      ./generate.sh -t mojave -p blur -i left -c dark -s 1080p
    '';

    installPhase = ''
      mkdir -p $out
      # generate.sh creates a named directory (e.g., Elegant-forest-window-left-dark).
      # NixOS expects the `theme.txt` to be right at the root of the theme path,
      # so we move the contents of that generated directory directly into $out.
      cp -r Elegant-*/* $out/
    '';
  };

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
      ] ++ lib.optional (builtins.pathExists /home/niri-dank/.config/1-negro/nixos-config.nix) /home/niri-dank/.config/1-negro/nixos-config.nix
        ++ lib.optional (builtins.pathExists ./local-hardware.nix) ./local-hardware.nix;

  # =========================================
  # System Settings (Boot, Network, Time)
  # =========================================
  system.stateVersion = "23.11";

  systemd.settings = {
    Manager = {
      DefaultTimeoutStopSec = "20s";
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages =[ "openssl-1.1.1w" ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters =[
      "https://nix-community.cachix.org"
      "https://attic.xuyh0120.win/lantian"
      "https://cache.garnix.io"
    ];
    trusted-public-keys =[
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  boot = {
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
    kernelModules =[ "i2c-dev" "i2c-piix4" "nct6775" ];
    loader = {
      systemd-boot.enable = false;
      timeout = 5;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };

      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";

        useOSProber = false;

        configurationLimit = 1;

        extraEntries = ''
          menuentry "Windows" --class windows --class os {
            insmod part_gpt
            insmod fat
            search --no-floppy --set=root --file /EFI/Microsoft/Boot/bootmgfw.efi
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';

        theme = elegant-grub-theme;
        gfxmodeEfi = "auto";
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
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    i2c.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      # videoDrivers = [ "nvidia" ];
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
    nh = {
      enable = true;
      flake = "/etc/nixos";
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 3";
      };
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true; # steam in gamescope
    };
    gamemode.enable = true;
    gamescope = {
          enable = true;
          capSysNice = true;
        };
  };

  programs.git = {
    enable = true;
    config.safe.directory = "/etc/nixos";
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
      eza tmux capitaine-cursors zed-editor obsidian thunar
      pixel-sddm
      kdePackages.qtwayland kdePackages.qtsvg kdePackages.qtdeclarative kdePackages.qt5compat
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

      # alias

      (pkgs.writeShellScriptBin "jew" ''
        # Pull from git
        if [ "$1" == "down" ]; then
            echo "WHERE?!?!?"
            sudo git -C /etc/nixos pull --rebase --autostash
            sudo chown -R niri-dank:main /etc/nixos
            shift
        fi

        # up or nah
        PUSH_AFTER_BUILD=0
        if [ "$1" == "up" ]; then
            echo "yes king."
            PUSH_AFTER_BUILD=1
            shift
        fi

        # stage
        git -C /etc/nixos add .

        # 4. Logic
        if [ "$PUSH_AFTER_BUILD" -eq 1 ]; then
            if nh os switch /etc/nixos -- --impure "$@"; then
                echo "Build success. Committing & pushing to Git...ni-"

                # Commit
                git -C /etc/nixos commit -m "eh" || echo "No new changes to commit."

                # Push
                git -C /etc/nixos push
            else
                echo "Build failed gang. Aborting Git push."
                exit 1
            fi
        else
            exec nh os switch /etc/nixos -- --impure "$@"
            echo "Baij bailda psda baas shidne shu..."
        fi
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
    "d /home/niri-dank 0700 niri-dank main - -"
    "d /home/niri-dank/.config 0755 niri-dank main - -"
    "d /var/sddm-background 0777 root root -"
    "d /home/niri-dank/.config/1-negro 0775 niri-dank main - -"
    "d /home/niri-dank/.config/DankMaterialShell 0755 niri-dank main - -"
    "C /home/niri-dank/.config/DankMaterialShell/settings.json 0664 niri-dank main - /etc/nixos/dotfiles/DankMaterialShell/settings.json"
    "f /home/niri-dank/.config/1-negro/nixos-config.nix 0664 niri-dank main - { config, pkgs, ... }:\\n{\\n  environment.systemPackages = with pkgs;[\\n    # Custom packages. Jew.\\n\\n  ];\\n\\n  # =========================================\\n  # External Drive Mount Template\\n  # =========================================\\n  # Uncomment and replace UUID to use\\n  # fileSystems.\\\"/mnt/Large\\\" = {\\n  #   device = \\\"/dev/disk/by-uuid/F674F18774F14B3F\\\";\\n  #   fsType = \\\"ntfs-3g\\\";\\n  #   options =[\\n  #     \\\"users\\\"\\n  #     \\\"nofail\\\"\\n  #     \\\"x-systemd.automount\\\"\\n  #     \\\"x-systemd.device-timeout=5s\\\"\\n  #\\n  #     # --- Permission Fixes ---\\n  #     \\\"uid=niri-dank\\\" # set owner to niri-dank \\n  #     \\\"gid=main\\\"      # set group to main \\n  #     \\\"rw\\\"            # read/write \\n  #     \\\"umask=0002\\\"    # give 'main' full write permissions (775/664)\\n  #   ];\\n  # };\\n}\\n"
    "f /home/niri-dank/.config/1-negro/niri-config.kdl 0664 niri-dank main - // Custom niri config. Jew.\\n"
    "d /home/niri-dank/.config/pandora 0755 niri-dank main - -"
    "f /home/niri-dank/.config/pandora/pandora.kdl 0664 niri-dank main - output \"*\" {\\n    image \"/home/niri-dank/Pictures/Wallpaper/muntan1.jpg\"\\n    mode \"scroll-vertical\"\\n}\\n\\nanimation {\\n    slowdown 2.0\\n}\\n"
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
      inputs.mangowm.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
