# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

let
  pixel-sddm = pkgs.stdenv.mkDerivation {
    pname = "pixel-sddm";
    version = "1.0";
    src = pkgs.fetchFromGitHub {
      owner = "mahaveergurjar";
      repo = "sddm";
      rev = "pixel"; 
      hash = "sha256-bzA6WUZrXgQDJvOuK5JIcnPJNRhU/8AiKg3jgAeeoBM="; 
    };
    
    # Added matugen (Material You generator) and jq (JSON parser)
    nativeBuildInputs =[ pkgs.imagemagick pkgs.matugen pkgs.jq ];

    installPhase = ''
      mkdir -p $out/share/sddm/themes/Pixel
      find . -type f -name "*.qml" -exec sed -i 's/QtGraphicalEffects/Qt5Compat.GraphicalEffects/g' {} +
      
      cp -r * $out/share/sddm/themes/Pixel/

      # 1. Convert wallpaper to PNG
      magick ${./sddm-wall/wallpaper.jpg} $out/share/sddm/themes/Pixel/my-wallpaper.png
      
      # 2. Fast-calculate the average dominant color of the image using ImageMagick
      DOMINANT_HEX=$(magick ${./sddm-wall/wallpaper.jpg} -scale 1x1\! -format "%[hex:u.p{0,0}]" info:)
      
      # 3. Generate the Material You palette from the hex color directly!
      matugen color hex "#$DOMINANT_HEX" -j hex > palette.json
      
      # 4. Read the colors we want
      ACCENT=$(jq -r '.colors.dark.primary' palette.json)
      SURFACE=$(jq -r '.colors.dark.surface' palette.json)
      TEXT=$(jq -r '.colors.dark.on_surface' palette.json)

      # 5. Feed them into the SDDM override config
      cat > $out/share/sddm/themes/Pixel/theme.conf.user <<EOF[General]
      Background="my-wallpaper.png"
      background="my-wallpaper.png"
      AccentColor="$ACCENT"
      PrimaryColor="$ACCENT"
      BackgroundColor="$SURFACE"
      TextColor="$TEXT"
      EOF

      # 6. FORCE OVERRIDE (Only uncomment if Step 5 doesn't change the UI colors!)
      # find $out/share/sddm/themes/Pixel/ -type f -name "*.qml" -exec sed -i "s/#REPLACE_ME/$ACCENT/gi" {} +
    '';
  };

  inir-quickshell = pkgs.stdenv.mkDerivation {
    pname = "inir-quickshell";
    version = "custom";

    dontUnpack = true;

    # The magic bullet: this hook automatically generates flawless Qt wrappers
    nativeBuildInputs = [ pkgs.kdePackages.wrapQtAppsHook ];

    # All the KDE/Qt modules iNiR will ever need
    buildInputs = with pkgs.kdePackages;[
      kirigami
      kirigami-addons
      qtmultimedia
      qtdeclarative
      syntax-highlighting
      plasma-integration
      qtimageformats
      qtwayland
      qt5compat
      qtsvg
    ];

    installPhase = ''
      mkdir -p $out/bin
      
      # We specifically COPY the binaries instead of symlinking them.
      # This allows wrapQtAppsHook to rename the original to '.qs-wrapped'
      # and put a beautifully configured bash script in its place.
      cp -a ${pkgs.quickshell}/bin/* $out/bin/
    '';
  };
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.mangowm.nixosModules.mango
    ];

  programs.mango.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;  # Instantly boot without showing the menu
  boot.loader.systemd-boot.configurationLimit = 5; # Keep only the last 5 builds in the boot menu

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Ulaanbaatar";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups.main = {};

  users.users."niri-dank" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "main" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  users.users."niri-noctalia" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "main" ]; # Gives sudo privileges
    shell = pkgs.fish;
    packages = with pkgs; [
      tree
    ];
  };

  # =========================================
  # ##! niri-inir (Niri / snowarch/inir) User
  # =========================================
  users.users."niri-inir" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "main" "video" "audio" "networkmanager" ];
    shell = pkgs.fish;
    
    # Packages isolated STRICTLY to this user to prevent global conflicts
    packages = with pkgs;[
      # Core Wayland & Niri Utils
      inir-quickshell
      wl-clipboard
      cliphist
      grim
      slurp
      matugen
      fuzzel
      
      # ===============================================================
      # black jew nigger gang
      # ===============================================================

      swww
      (runCommand "awww-alias" {} ''
        mkdir -p $out/bin
        ln -s ${pkgs.swww}/bin/swww $out/bin/awww
        ln -s ${pkgs.swww}/bin/swww-daemon $out/bin/awww-daemon
      '')


      # ===============================================================
      # black jew nigger gang
      # ===============================================================

      # hyprlax
      
      # # 1. Fake swww: Intercepts the image path and launches hyprlax
      # (pkgs.writeShellScriptBin "swww" ''
      #   for arg in "$@"; do
      #     if [ -f "$arg" ]; then
      #        WALLPAPER="$arg"
             
      #        # Kill the old hyprlax
      #        pkill hyprlax
             
      #        # Launch hyprlax detached so it stays alive in the background
      #        nohup hyprlax "$WALLPAPER" >/dev/null 2>&1 &
             
      #        # Generate color palette for Quickshell
      #        matugen image "$WALLPAPER"
             
      #        exit 0
      #     fi
      #   done
      #   exit 0
      # '')

      # # 2. Fake awww: Quickshell relies on this command
      # (pkgs.writeShellScriptBin "awww" ''
      #   exec swww "$@"
      # '')

      # # 3. Dummy Daemons: Prevents crashes on startup
      # (pkgs.writeShellScriptBin "swww-daemon" ''
      #   exec sleep infinity
      # '')
      # (pkgs.writeShellScriptBin "awww-daemon" ''
      #   exec sleep infinity
      # '')

      # ===============================================================
      # black jew nigger gang
      # ===============================================================



      jq                  # Crucial for parsing JSON colors in iNiR scripts
      bc                  # Crucial for math (volume/brightness sliders)
      ripgrep             # Fast text searching in scripts
      curl                # Downloading assets/weather
      rsync               # File syncing
      libnotify           # Powers the notification daemon
      imagemagick         # Used for wallpaper blurring and image processing

      playerctl           # Media controls (also fixes your Mod+Shift+P keybind!)
      brightnessctl       # Screen brightness controls
      libqalculate        # Powers the shell's calculator widget
      translate-shell     # Powers the translation widget
      cava                # Audio visualizer for the top bar/music menu
      swappy              # iNiR's default screenshot editor
      tesseract           # OCR engine for extracting text from screen
      wtype               # Wayland typing simulation
      ydotool             # Input simulation fallback
      wlsunset

      gsettings-desktop-schemas
      procps              # provides pidof, pgrep
      coreutils           # provides whoami, df
      findutils           # provides find
      glib                # provides gsettings
      kdePackages.kconfig # provides kwriteconfig6
      ddcutil             # monitor brightness control
      xdg-utils           # provides xdg-settings
      yt-dlp              # ytmusic background scraping
      deno
      mpv                 # video/audio background playing
      swayidle            # idle manager
      wf-recorder
      # Runtime extras
      socat
      fprintd

      # KDE Dialogs (Executable used by some iNiR scripts)
      kdePackages.kdialog

      (python3.withPackages (ps: with ps; [
        evdev
        pillow
      ]))
    ];
  };

  # =========================================
  # ##! mango-dank (MangoWM + DMS) User
  # =========================================
  users.users."mango-dank" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "main" "video" "audio" "networkmanager" ];
    shell = pkgs.fish;
    
    # Packages isolated STRICTLY to the mango-dank user
    packages = with pkgs;[
      # Core end-4/DMS Aesthetic Dependencies
      matugen
      swww
      wl-clipboard
      cliphist
      grim
      slurp
      jq
      brightnessctl
      playerctl
      libnotify
      swappy
      cava
      libqalculate

      inputs.mangowm.packages.${pkgs.system}.default
      
      # NOTE: If you have a mangowm package in your flake inputs, add it here! 
      # e.g., inputs.mangowm.packages.${pkgs.system}.default
    ];
  };

  # Enable Hyprland system-wide so SDDM creates a login entry for it.
  # Note: This does NOT conflict with Niri!
  programs.hyprland.enable = true;

  # programs.firefox.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    kitty
    vesktop
    sublime4
    yazi
    pavucontrol
    easyeffects
    starship
    obs-studio
    obsidian
    steam
    gnome-disk-utility
    hyprpolkitagent
    qdirstat
    eza
    pixel-sddm
    kdePackages.qtwayland
    kdePackages.qtsvg
    kdePackages.qtdeclarative
    kdePackages.qt5compat
    tmux
    inputs.zen-browser.packages.${pkgs.system}.default
    capitaine-cursors
  ];

systemd.tmpfiles.rules =[
    "d /var/sddm-background 0777 root root -"
  ];

  # Install Nerd Fonts for terminal icons
  fonts.packages = with pkgs;[
    nerd-fonts.jetbrains-mono
    material-symbols
    rubik
    # --- MISSING: Core System & Web Fallback Fonts ---
    # These prevent weird text rendering on websites and legacy apps
    dejavu_fonts        # Equates to ttf-dejavu
    liberation_ttf      # Equates to ttf-liberation

    # --- MISSING: Emoji Font ---
    # Equates to ttf-twemoji (Provides colorful Twitter emojis system-wide)
    twemoji-color-font  
    
    # Note: 'ttf-readex-pro' is also in the Arch list, but it isn't packaged 
    # individually in Nixpkgs. The iNiR shell will seamlessly fall back 
    # to Rubik or Space Grotesk without it, so you don't need to worry about it!
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

nix.settings.experimental-features = [ "nix-command" "flakes" ];

	nixpkgs.config.allowUnfree = true;
	nixpkgs.config.permittedInsecurePackages = [
 	 "openssl-1.1.1w"
	];

	programs.niri.enable = true;

  # Enable MangoWM (If supported by your channels/flakes)
  # programs.mangowm.enable = true; 

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    theme = "Pixel";

    package = pkgs.kdePackages.sddm;
    
    # Inject Qt6 compatibility libraries directly into SDDM
    extraPackages = with pkgs.kdePackages;[
      qt5compat
      qtdeclarative
      qtsvg
      qtimageformats
    ];
  };

	programs.dconf.enable = true;

        # Enable the Fish shell
	programs.fish.enable = true;
	programs.starship = {
    		enable = true;
    		# (Optional) You can set a preset theme here if you want!
  	};

  # Enable Nix Helper (nh)
  programs.nh = {
    enable = true;
    # Tells nh exactly where to look so you never have to type --flake again
    flake = "/etc/nixos"; 
    
    # (Optional) nh also comes with a great automatic garbage collector!
    # This cleans up old NixOS generations older than 7 days so your drive doesn't fill up.
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 3";
  };

	# Enable RealtimeKit for audio priority
	security.rtkit.enable = true;

  	# Enable the PipeWire audio server
  	services.pipewire = {
    		enable = true;
    		alsa.enable = true;
    		alsa.support32Bit = true;
    		pulse.enable = true; # Makes PipeWire pretend to be PulseAudio so older apps work
 	 };

	hardware.graphics.enable = true;
	services.xserver.videoDrivers = [ "nvidia" ];
	
	hardware.nvidia = {
		modesetting.enable = true;
		powerManagement.enable = false;
		powerManagement.finegrained = false;
		open = false;
		nvidiaSettings = true;
		package = config.boot.kernelPackages.nvidiaPackages.stable;
	};

	environment.sessionVariables = {
		# Hints electron apps to use wayland
		NIXOS_OZONE_WL = "1";
	};
  environment.pathsToLink = [ "/share/icons" ];

environment.etc."niri/shared-binds.kdl".text = ''
    recent-windows {
        // By default, Niri delays the menu slightly so quick Alt-Tabs don't flash the screen.
        // Set to 0 if you want it to appear instantly.
        open-delay-ms 50
	binds {
		Alt+Tab { next-window; }
	}
    }
    binds {
        // =========================================
        // ##! Apps
        // =========================================
        Mod+Return { spawn "kitty"; }
        Mod+B { spawn "zen"; }
        Mod+E { spawn "kitty" "-e" "yazi"; }
        Mod+C { spawn "subl"; } // Sublime Text
        Mod+Ctrl+Alt+Shift+W { spawn "libreoffice"; } 
        Ctrl+Shift+Escape { spawn "kitty" "-e" "btop"; }
        Mod+Ctrl+V { spawn "pavucontrol"; }
        
        // =========================================
        // ##! Window Management
        // =========================================
        Mod+Q { close-window; }
        Mod+W { toggle-window-floating; }
        Mod+F { fullscreen-window; }
        
        // Toggle the focused window width (Closest to Mod+D colresize)
        Mod+S { switch-preset-column-width; }

        // Make the window take the whole screen, but keep gaps/bar (Maximized)
        Mod+D { maximize-column; }

        // Focus windows
        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up    { focus-window-up; }
        Mod+Down  { focus-window-down; }

        Mod+Ctrl+Left  { focus-column-left; }
        Mod+Ctrl+Right { focus-column-right; }

        // Move windows left/right
        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }

        // Pull window out of vertical column into horizontal (Closest to Mod+Space Promote)
        Mod+Space { consume-or-expel-window-left; }

        // Note: Moving and Resizing with the Mouse (Super+Mouse272) is handled 
        // natively by Niri: Just hold Super + Left Click to move, and Super + Right Click to resize!

        // =========================================
        // ##! Workspaces
        // =========================================
        // Toggle the Niri Workspace Overview (Win + Tab)
        Mod+Tab { toggle-overview; }

        // Focus Workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

        // Send to Workspaces
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }

        // Switch workspaces with Arrow Keys
        Mod+Ctrl+Up   { focus-workspace-up; }
        Mod+Ctrl+Down { focus-workspace-down; }

        // Switch workspaces with Mouse Scroll
        Mod+WheelScrollUp   { focus-workspace-up; }
        Mod+WheelScrollDown { focus-workspace-down; }

        // Move windows to up/down workspaces
        Mod+Shift+Up   { move-window-to-workspace-up; }
        Mod+Shift+Down { move-window-to-workspace-down; }

        // =========================================
        // ##! Media, System & Utilities
        // =========================================
        Mod+Shift+P { spawn "playerctl" "play-pause"; }
        Mod+Shift+N { spawn "playerctl" "next"; }
        Mod+Shift+B { spawn "playerctl" "previous"; }
        
        Mod+Shift+C { spawn "hyprpicker" "-a"; }
        Mod+L       { spawn "loginctl" "lock-session"; }
        Mod+Shift+L { spawn "systemctl" "suspend"; }

        // Screenshots (Niri native)
        Print       { screenshot; }
        Mod+Print   { screenshot-window; }
    }
  '';
environment.variables = {
    # Set your terminal editor
    EDITOR = "subl"; 
  };

fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      emoji = [ "Twemoji" ];
    };
  };
  programs.coolercontrol.enable = true;

  # Allow the kernel to read Motherboard Fan Controllers & AIOs
  boot.kernelModules =[ 
    "i2c-dev"
    "i2c-piix4"
    "nct6775"     # Your specific Nuvoton motherboard chip!
  ];

  # Enable I2C hardware sensors (Required for CoolerControl)
  hardware.i2c.enable = true;

}

