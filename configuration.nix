# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

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
    
    # Add ImageMagick so Nix can convert the image for us
    nativeBuildInputs = [ pkgs.imagemagick ];

    installPhase = ''
      mkdir -p $out/share/sddm/themes/Pixel
      find . -type f -name "*.qml" -exec sed -i 's/QtGraphicalEffects/Qt5Compat.GraphicalEffects/g' {} +
      
      # 1. Copy the base theme files
      cp -r * $out/share/sddm/themes/Pixel/

      # 2. Fix the white screen: Convert your JPG to a PNG so Qt can natively read it
      magick ${./sddm-wall/wallpaper.jpg} $out/share/sddm/themes/Pixel/my-wallpaper.png
      
      # 3. Bypass sed completely by creating an SDDM override file
      cat > $out/share/sddm/themes/Pixel/theme.conf.user <<EOF
      [General]
      Background="my-wallpaper.png"
      background="my-wallpaper.png"
      EOF
    '';
  };
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

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
    pixel-sddm
  ];

systemd.tmpfiles.rules =[
    "d /var/sddm-background 0777 root root -"
  ];

  # Install Nerd Fonts for terminal icons
  fonts.packages = with pkgs;[
    nerd-fonts.jetbrains-mono
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
}

