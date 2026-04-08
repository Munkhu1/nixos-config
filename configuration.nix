{ config, lib, pkgs, inputs, ... }:

let
  # =========================================
  # Dynamic GRUB Resolution
  # =========================================
  grubConfigFile = "/home/niri-dank/.config/1-negro/grub-config.conf";

  # Read the file if it exists, otherwise fallback to 1920x1080
  grubRes = if builtins.pathExists grubConfigFile
            then lib.strings.trim (builtins.readFile grubConfigFile)
            else "1920x1080";

  # Map the raw resolution to the scale Elegant-GRUB expects
  themeScale = if grubRes == "3840x2160" then "4k"
               else if grubRes == "2560x1440" then "2k"
               else "1080p";

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
      ./generate.sh -t mojave -p blur -i left -c dark -s ${themeScale}
    '';

    installPhase = ''
      mkdir -p $out
      # generate.sh creates a named directory (e.g., Elegant-forest-window-left-dark).
      # NixOS expects the `theme.txt` to be right at the root of the theme path,
      # so we move the contents of that generated directory directly into $out.
      cp -r Elegant-*/* $out/
    '';
  };

  ii-sddm-theme = pkgs.stdenv.mkDerivation {
    pname = "ii-sddm-theme";
    version = "git";

    src = pkgs.fetchFromGitHub {
      owner = "3d3f";
      repo = "ii-sddm-theme";
      rev = "main";
      hash = "sha256-uTCFZ4/QmXKWY/JjQB29v6tgJr8n/10xnbE9HUIRWF8=";
    };

    nativeBuildInputs =[ pkgs.matugen pkgs.imagemagick ];

    installPhase = ''
        mkdir -p $out/share/sddm/themes/ii-sddm-theme
        cp -r * $out/share/sddm/themes/ii-sddm-theme/

        cp Matugen/SddmColors.qml $out/share/sddm/themes/ii-sddm-theme/SddmColors.qml
        cp Matugen/Settings.qml $out/share/sddm/themes/ii-sddm-theme/default-Settings.qml 2>/dev/null || true

        if [ -f Matugen/theme.conf ]; then
            cp Matugen/theme.conf $out/share/sddm/themes/ii-sddm-theme/theme.conf
        fi

        rm -rf $out/share/sddm/themes/ii-sddm-theme/{iiMatugen,noMatugen,Matugen,Previews}
        chmod -R +w $out/share/sddm/themes/ii-sddm-theme/

        find $out/share/sddm/themes/ii-sddm-theme -type f -name "*.qml" -exec sed -i 's|~/.config/ii-sddm-theme/|file:///var/sddm-background/|g' {} +

        mkdir -p $out/share/sddm/themes/ii-sddm-theme/Backgrounds
        rm -f $out/share/sddm/themes/ii-sddm-theme/Backgrounds/background.*
        rm -f $out/share/sddm/themes/ii-sddm-theme/Backgrounds/placeholder.*
        ln -sf /var/sddm-background/wallpaper.jpg $out/share/sddm/themes/ii-sddm-theme/Backgrounds/wallpaper.jpg

        mkdir -p $out/share/sddm/themes/ii-sddm-theme/Components
        rm -f $out/share/sddm/themes/ii-sddm-theme/Components/Colors.qml
        rm -f $out/share/sddm/themes/ii-sddm-theme/Components/Settings.qml
        ln -s /var/sddm-background/Colors.qml $out/share/sddm/themes/ii-sddm-theme/Components/Colors.qml
        ln -s /var/sddm-background/Settings.qml $out/share/sddm/themes/ii-sddm-theme/Components/Settings.qml

        if [ -f $out/share/sddm/themes/ii-sddm-theme/theme.conf ]; then
            sed -i 's|^Background=.*|Background="Backgrounds/wallpaper.jpg"|' $out/share/sddm/themes/ii-sddm-theme/theme.conf
            sed -i 's|^BackgroundPlaceholder=.*|BackgroundPlaceholder=""|' $out/share/sddm/themes/ii-sddm-theme/theme.conf
        else
            echo "[General]" > $out/share/sddm/themes/ii-sddm-theme/theme.conf
            echo 'Background="Backgrounds/wallpaper.jpg"' >> $out/share/sddm/themes/ii-sddm-theme/theme.conf
        fi

        if [ -f $out/share/sddm/themes/ii-sddm-theme/Themes/ii-sddm.conf ]; then
            sed -i 's|^Background=.*|Background="Backgrounds/wallpaper.jpg"|' $out/share/sddm/themes/ii-sddm-theme/Themes/ii-sddm.conf
            sed -i 's|^BackgroundPlaceholder=.*|BackgroundPlaceholder=""|' $out/share/sddm/themes/ii-sddm-theme/Themes/ii-sddm.conf
        fi

        if [ -f $out/share/sddm/themes/ii-sddm-theme/default-Settings.qml ]; then
            sed -i 's|Backgrounds/background.png|Backgrounds/wallpaper.jpg|g' $out/share/sddm/themes/ii-sddm-theme/default-Settings.qml
            sed -i 's|Backgrounds/placeholder.png||g' $out/share/sddm/themes/ii-sddm-theme/default-Settings.qml

            sed -i 's|panelFamily: "ii"|panelFamily: "waffle"|g' $out/share/sddm/themes/ii-sddm-theme/default-Settings.qml
        fi

        cat << EOF > matugen.toml
[config]
wallpaper_dir = "."
[templates.sddm]
input_path = "$out/share/sddm/themes/ii-sddm-theme/SddmColors.qml"
output_path = "default-Colors.qml"
EOF
        matugen --config matugen.toml color hex "#89b4fa"
        cp default-Colors.qml $out/share/sddm/themes/ii-sddm-theme/default-Colors.qml

        mkdir -p $out/share/fonts/truetype
        cp -r fonts/ii-sddm-theme-fonts/* $out/share/fonts/truetype/ 2>/dev/null || true
    '';
  };

in
{
  imports =[
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
      timeout = 1;

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
            savedefault   # <--- Tells GRUB to remember Windows if selected
            insmod part_gpt
            insmod fat
            search --no-floppy --set=root --file /EFI/Microsoft/Boot/bootmgfw.efi
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';

        theme = elegant-grub-theme;
        gfxmodeEfi = "${grubRes},auto";
      };
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    # extraHosts = ''
    #   140.82.113.3 github.com
    #   140.82.113.3 api.github.com
    # '';
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
    libinput = {
      enable = true;
      mouse = {
        accelProfile = "flat";
      };
      touchpad = {
        accelProfile = "flat";
      };
    };
    displayManager.defaultSession = "niri";
    xserver = {
      enable = true;
      # videoDrivers = [ "nvidia" ];
    };
    displayManager.sddm = {
      enable = true;
      wayland.enable = false;
      theme = "ii-sddm-theme";
      package = pkgs.kdePackages.sddm;
      extraPackages = with pkgs.kdePackages;[
        qt5compat qtdeclarative qtsvg qtimageformats
        qtvirtualkeyboard qtmultimedia pkgs.capitaine-cursors
      ];
      settings = {
        Theme = {
          CursorTheme = "capitaine-cursors-white";
          CursorSize = 24;
        };
        General = {
          InputMethod = "qtvirtualkeyboard";
          GreeterEnvironment = "QML2_IMPORT_PATH=${ii-sddm-theme}/share/sddm/themes/ii-sddm-theme/Components/,QT_IM_MODULE=qtvirtualkeyboard";
        };
      };
      setupScript = ''
        ${pkgs.xorg.xrdb}/bin/xrdb -merge - <<EOF
        Xcursor.theme: capitaine-cursors-white
        Xcursor.size: 24
        EOF

        ${pkgs.xorg.xset}/bin/xset m 0 0

        ${pkgs.xorg.xrandr}/bin/xrandr | ${pkgs.gawk}/bin/awk '
          / connected/ {
            out = $1
            getline
            res = $1
            max = 0
            for (i=2; i<=NF; i++) {
              val = $i + 0
              if (val > max) max = val
            }
            system("${pkgs.xorg.xrandr}/bin/xrandr --output " out " --mode " res " --rate " max)
          }
        '
      '';
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
    niri = {
          enable = true;
          package = pkgs.niri-unstable; # blur fork
        };
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
      wget git kitty vesktop sublime4 yazi pavucontrol easyeffects starship nautilus matugen xwayland-satellite
      obs-studio obsidian steam gnome-disk-utility hyprpolkitagent qdirstat btop libreoffice
      eza tmux capitaine-cursors zed-editor obsidian thunar swww imagemagick mangohud
      ii-sddm-theme
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
            echo "Baij bailda psda baas shidne shu..."
            exec nh os switch /etc/nixos -- --impure "$@"
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
      ii-sddm-theme
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
    "C /var/sddm-background/Colors.qml 0666 root root - ${ii-sddm-theme}/share/sddm/themes/ii-sddm-theme/default-Colors.qml"
    "C /var/sddm-background/wallpaper.jpg 0666 root root - ${./sddm-wall/wallpaper.jpg}"
    "d /home/niri-dank/.config/1-negro 0775 niri-dank main - -"
    "d /home/niri-dank/.config/DankMaterialShell 0755 niri-dank main - -"
    "C /home/niri-dank/.config/DankMaterialShell/settings.json 0664 niri-dank main - /etc/nixos/dotfiles/DankMaterialShell/settings.json"
     "f /home/niri-dank/.config/1-negro/nixos-config.nix 0664 niri-dank main - { config, pkgs, ... }:\\n{\\n  environment.systemPackages = with pkgs;[\\n    # Custom packages. Jew.\\n\\n  ];\\n\\n  # =========================================\\n  # Drive Mount Template\\n  # =========================================\\n  # Uncomment and replace UUID / fsType to use\\n  # fileSystems.\\\"/mnt/Win_D-Drive\\\" = {\\n  #   device = \\\"/dev/disk/by-uuid/REPLACE_ME\\\";\\n  #   fsType = \\\"ntfs-3g\\\"; # btrfs, ext4, etc.\\n  #   options =[\\n  #     \\\"users\\\"\\n  #     \\\"exec\\\"\\n  #     \\\"nofail\\\"\\n  #     \\\"x-gvfs-show\\\"\\n  #\\n  #     # --- Enable ONLY for removable USBs ---\\n  #     # \\\"x-systemd.automount\\\"\\n  #     # \\\"x-systemd.device-timeout=5s\\\"\\n  #\\n  #     \\\"uid=niri-dank\\\" # set owner to niri-dank \\n  #     \\\"gid=main\\\"      # set group to main \\n  #     \\\"rw\\\"            # read/write \\n  #     \\\"umask=0002\\\"    # full write permissions for \`main\`\\n  #   ];\\n  # };\\n}\\n"
    "f /home/niri-dank/.config/1-negro/niri-config.kdl 0664 niri-dank main - // Custom niri config. Jew.\\n"
    "d /home/niri-dank/.config/pandora 0755 niri-dank main - -"
    "f /home/niri-dank/.config/pandora/pandora.kdl 0664 niri-dank main - output \"*\" {\\n    image \"/home/niri-dank/Pictures/Wallpaper/muntan1.jpg\"\\n    mode \"scroll-vertical\"\\n}\\n\\nanimation {\\n    slowdown 2.0\\n}\\n"
    "C /var/sddm-background/Settings.qml 0666 root root - ${ii-sddm-theme}/share/sddm/themes/ii-sddm-theme/default-Settings.qml"
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
}
