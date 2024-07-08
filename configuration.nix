# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "vivaldi"
      "vivaldi-6.2"
  ];
nixpkgs.config.allowUnfree = true;
in
{
  imports =
    [ # Include the results of the hardware scan.
   #   <nixos-hardware/system76/default.nix>
      ./hardware-configuration.nix
      ./falcon-sensor.nix
    ];
  boot.supportedFilesystems = [ "ntfs" ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
   
  boot.extraModprobeConfig = ''
    options snd snd_hda_codec_realtek
    options snd_hda_intel enable=0,1
    options kvm-amd nested=1 avic=1
    options kvm ignore_msrs=Y report_ignored_msrs=N
  '';
  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Enable swap on luks
  boot.initrd.luks.devices."luks-5e433a08-e87f-4fb1-b6d6-f98e6652126c".device = "/dev/disk/by-uuid/5e433a08-e87f-4fb1-b6d6-f98e6652126c";
  boot.initrd.luks.devices."luks-5e433a08-e87f-4fb1-b6d6-f98e6652126c".keyFile = "/crypto_keyfile.bin";
  
  # sysctl
  boot.kernel.sysctl = {
	"vm.compaction_proactiveness" = 0;
	"vm.swappiness" = 0;
        "fs.aio-max-nr" = 1048576;
  };
  # latest kernel
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "nixos"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  nixpkgs.overlays = [
    (
      self: super: {
        falcon-sensor = super.callPackage ./overlays/falcon-sensor.nix { };
      }
    )
  ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.powerManagement.enable = true;
  hardware.system76.enableAll = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb = { 
      variant = "";
      layout = "us";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = false;
  hardware.pulseaudio.enable = false;
  
 # virtualisation.libvirtd.qemu.swtpm.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "suspend";
    onBoot = "ignore";
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true;
      ovmf.packages = [ pkgs.OVMFFull.fd ];
      swtpm.enable = true;
  };
};
  services.spice-vdagentd.enable = true;
  services.spice-webdavd.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;
  programs.dconf.enable = true; # virt-manager requires dconf to remember settings
  hardware.bluetooth.enable = true;

   # Nix garbage collector settings.
   nix = {
     gc = {
       automatic = true;
       dates = "weekly";
       options = "--delete-older-than 120d";
     };
    optimise.automatic = true;
    settings = {
      auto-optimise-store = true;
    };
  };


  #  hardware.tuxedo-rs = {
  #    enable = true;
  #    tailor-gui.enable = true;
  #  };
  hardware.tuxedo-keyboard.enable = true;

  #hardware.bluetooth.hsphfpd.enable = true;
  security.rtkit.enable = true;
  systemd.user.services.telephony_client.enable = false;
  services.hardware.bolt.enable = true;
  services.udev.packages = [
    pkgs.android-udev-rules
  ];
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="deadline"
  '';
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    wireplumber.enable = true;
};
 environment.etc = {
	"wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
		bluez_monitor.properties = {
			["bluez5.enable-sbc-xq"] = true,
			["bluez5.enable-msbc"] = true,
			["bluez5.enable-hw-volume"] = true,
			["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
		}
	'';
  "ovmf/edk2-x86_64-secure-code.fd" = {
    source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-x86_64-secure-code.fd";
  };

  "ovmf/edk2-i386-vars.fd" = {
    source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-i386-vars.fd";
  };
};

   services.locate = {
        enable = true;
        package = pkgs.mlocate;
        interval = "hourly";
        localuser = null;
   };
  custom.falcon.enable = true;
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mihai = {
    isNormalUser = true;
    description = "Mihai";
    extraGroups = ["networkmanager" "wheel" "video" "dbus" "input" "audio" "kvm" "libvirtd" "qemu-libvirtd"];
    packages = with pkgs; [
      firefox
      kate
    #  thunderbird
    ];
  };

  # Allow unfree packages
#  nix.settings.experimental-features = "nix-command why-depends"
  
  # List packages installed in system profile. To search, run:
  # $ nix search wget
        

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    terminator
    wget
    lsof
    pciutils
    procps
    htop
    iotop
    #android-tools
    #signify
    mlocate
    #libtree
#    pax-util
    plasma-pa
    git
    plasma5Packages.plasma-thunderbolt
    #pulseaudioFull
    alsa-utils
    #rpi-imager
    #aircrack-ng
    autorandr

    qemu
    virt-manager
    virt-viewer
    swtpm
    spice
    spice-gtk
    spice-protocol
    spice-vdagent
    win-spice

    qrencode
    OVMFFull
    OVMF
    #_1password
    gst_all_1.gstreamer
    # Common plugins like "filesrc" to combine within e.g. gst-launch
    gst_all_1.gst-plugins-base
    # Specialized plugins separated by quality
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
#   gst_all_1.gst-plugins-pipewire
    # Plugins to reuse ffmpeg to play almost every video format
    gst_all_1.gst-libav
    # Support the Video Audio (Hardware) Acceleration API
    gst_all_1.gst-vaapi
 
    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = false;
    })
    vivaldi-ffmpeg-codecs
    widevine-cdm
  ];

  boot.kernelParams = [ 
    "transparent_hugepage=never"
    "hugepagesz=1G"
    "hugepages=8"
    "tuxedo_keyboard.mode=0"
    "tuxedo_keyboard.brightness=25"
    "tuxedo_keyboard.color_left=0x0000ff"
];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };
  programs.partition-manager.enable = true;
  nix.settings.trusted-users = [ "root" "@wheel" "@mihai" ];
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
