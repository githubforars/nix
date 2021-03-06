{ config, pkgs,  ... }: {
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  fileSystems."/".device = "/dev/disk/by-label/nixos";

  swapDevices = [
	 {
            device = "/dev/disk/by-label/swap";
         }
  ];

  networking.firewall.allowedTCPPorts = [ 5000 ];

  users.extraUsers.demo = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "wheel"
    ];
  };

  system.stateVersion = "17.03";
  services.sshd.enable = true;

  environment.systemPackages = with pkgs; [
    ( mongodb )
    ( python35.withPackages (
        ps: with ps; [
          flask
          werkzeug
          pymongo
	  pep8
          bcrypt
          six
        ]
      )
    )
    ( stdenv.mkDerivation rec {
        name = "env";
        unpackPhase = "true";
        buildPhase = "true";
        src = fetchFromGitHub {
          owner = "githubforars";
          repo = "uploadapi";
          rev = "master";
          sha256 = "08fl0zq3wgrwicz4m70b0q6yjcc2ls00x8nb1kbvqm3bhfjy78km";
        };
        installPhase = ''
        mkdir -p $out/bin/
        cp $src/upload-api.py $out/bin
        chmod +x $out/bin/upload-api.py
        '';
        }
      )
    ];

  services.mongodb.enable = true;

  systemd.services.upload-api = {
    description = "API service for file upload";
    serviceConfig = {
      Type = "forking";
      ExecStart = "/run/current-system/sw/bin/upload-api.py";
      ExecStop = "pkill upload-api.py";
      Restart = "on-failure";
    };
    wantedBy = [
      "default.target"
    ];
    enable = true;
   };
}
