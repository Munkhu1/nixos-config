# Guide

### Installation
1. `sudo nmtui` to connect to da ethzernet. (ignore if ur connected via eth).

2. `lsblk` to check which drive/partition to sacrifice to nixos.

3. `curl -O https://raw.githubusercontent.com/Munkhu1/nixos-config/refs/heads/main/install.sh`

4. `chmod +x install.sh`

5. `sudo ./install.sh /dev/[UR SHIT]`

6. `reboot`

### Hardware config
Ask me WITH the contents of `nix shell nixpkgs#lshw -c lshw -c display`. Which shall be put in 

# To-do
- [x] cachyos kernel switch to satisfy munkhochir/more fps
- [x] mouse follow scroll fix
- [x] pandora wp
- [x] zeditor config symlink might not be working? gay.
- [x] nvidia/amd driver shit
- [x] permanent external drive mount guide/ish
- [x] maybe dms config sync 
- [x] fucking tetrio for munkhochir
- [x] also rog control center
- [x] grub menu looks dogshit.
- [ ] munkhochir's dogshit mic
- [ ] sddm customization
- [ ] diabolical keybind list organize
- [ ] test installation script on the same drive with windows, (might fuck windows boot partition)
- [ ] special workspace
