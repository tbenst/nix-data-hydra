{
    network = {
    description = "Hydra server";
    enableRollback = true;
  };

  hydra-server = {pkgs, lib, ...}: let
    upload_to_cachix = pkgs.writeScriptBin "upload-to-cachix"
      # TODO: add || return 2,3,4, etc to see where erroring?
      ''#!/bin/sh
      echo $OUT_PATHS > /tmp/posthook_out_paths
      set -eu
      set -f # disable globbing
      export IFS=' '

      # filter out CUDA to avoind possible license issues
      # https://github.com/NixOS/nixpkgs/pull/76233
      export NO_CUDA_PATHS=$(echo -e $OUT_PATHS | sed 's/\s\+/ \n/g' | grep -v cuda | tr -d '\n')
      export FILTERED_PATHS=$(echo -e $OUT_PATHS | sed 's/\s\+/ \n/g' | grep cuda | tr -d '\n')
      echo -e "Ignored the following paths (may be none):\n" $FILTERED_PATHS
      echo -e "Uploading paths:\n" $OUT_PATHS
      exec ${cachix}/bin/cachix -c /etc/cachix/cachix.dhall push nix-data $NO_CUDA_PATHS
      '';

    cachix = import (pkgs.fetchFromGitHub {
      owner = "cachix";
      repo = "cachix";
      rev = "26264f748d25284a2ea762aec7c40eab0412b4b2";
      sha256 = "0dy87imh4pg1kjm0ricvzk8gzvl66j08wyr2m3qfxypqbf7s5nyk";
    });
  in {
    imports = [./. ];

    users.users.root.hashedPassword = (builtins.readFile
      /Computer/secrets/hashed_passwords/hydra.key);

    # virtualisation = {
    #   graphics = false;
    #   memorySize = 8000; # M
    #   diskSize = 50000; # M
    #   writableStoreUseTmpfs = false;
    # };

    nixpkgs.config = {
      whitelistedLicenses = with lib.licenses; [
        unfreeRedistributable
        issl
      ];
      
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "cudnn_cudatoolkit"
        "cudatoolkit"
      ];
    };

    environment.etc."cachix/cachix.dhall".source = ./secrets/cachix.dhall;

    nix = {
      buildMachines = [
        # { hostName = "perkeep.mooch.rip";
        #   maxJobs = 8;
        #   sshKey = "/var/lib/hydra/.ssh/perkeep_rsa";
        #   sshUser = "hydra";
        #   system = "x86_64-linux";
        # }
      ];

      distributedBuilds = true;

      extraOptions = ''
        allowed-uris = https://github.com/tbenst/nixpkgs/archive/ https://github.com/NixOS/nixpkgs-channels/archive/ https://github.com/NixOS/nixpkgs/archive/
        builders-use-substitutes = true
        post-build-hook = ${upload_to_cachix}/bin/upload-to-cachix
      '';
      # TODO: distribute publicly
      # until distribution licenses are sorted out, private only for legality
      sshServe = {
        enable = true;
        keys = lib.splitString "\n" (builtins.readFile ./secrets/nix-ssh_pub.key);
      };
    };
    simple-hydra = {
      enable = true;
      hostName = "hydra.nix-data.org";
      useNginx = true;
      localBuilder.maxJobs = 1;
      # TODO use S3 for binary caching
      # but will need to come up with strategy to keep costs under control
      # https://github.com/NixOS/nixos-org-configurations/blob/63cb1725f4d8ddebf44c2789c005b673dad93836/delft/hydra.nix#L37
      # storeUri = "s3://nix-cache?secret-key=/var/lib/hydra/queue-runner/keys/cache.nixos.org-1/secret&write-nar-listing=1&ls-compression=br&log-compression=br"
    };

    environment.systemPackages = with pkgs; [
      cachix
      fd
      git
      htop
      iotop
      ncdu
      nethogs
      tmux
      upload_to_cachix
      vim
    ];

    services.openssh = {
      enable = true;
      passwordAuthentication = false;
    };

    services.fail2ban.enable = true;

    security.acme = {
      email = "nix-data@tylerbenster.com";
      acceptTerms = true;
    };

    networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  };
}
