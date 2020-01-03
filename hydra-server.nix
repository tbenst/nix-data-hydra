{
    network = {
    description = "Hydra server";
    enableRollback = true;
  };

  hydra-server = {pkgs, ...}: {
    imports = [./. ];

    users.users.root.hashedPassword = (builtins.readFile
      /Computer/secrets/hashed_passwords/hydra.key);

    # virtualisation = {
    #   graphics = false;
    #   memorySize = 8000; # M
    #   diskSize = 50000; # M
    #   writableStoreUseTmpfs = false;
    # };

    # Uncomment and fill in to support remote builders, like macOS.
    # nix.buildMachines = [
    #   {
    #     hostName = "<host>";
    #     sshUser = "<uxer>";
    #     sshKey = "<path to key>";
    #     system = "x86_64-darwin";
    #     maxJobs = 1;
    #   }
    # ];
    nix = {
      extraOptions = ''
        allowed-uris = https://github.com/tbenst/nixpkgs/archive/
      '';
      # TODO: distribute publicly
      # until distribution licenses are sorted out, private only for legality
      sshServe = {
        enable = true;
        keys = lib.splitString "\n" (builtins.readFile /Computer/home/ssh/authorized_keys);
      };
    };
    simple-hydra = {
      enable = true;
      hostName = "hydra.tylerbenster.com";
      useNginx = true;
      localBuilder.maxJobs = 1;
      # TODO use S3 for binary caching
      # but will need to come up with strategy to keep costs under control
      # https://github.com/NixOS/nixos-org-configurations/blob/63cb1725f4d8ddebf44c2789c005b673dad93836/delft/hydra.nix#L37
      # storeUri = "s3://nix-cache?secret-key=/var/lib/hydra/queue-runner/keys/cache.nixos.org-1/secret&write-nar-listing=1&ls-compression=br&log-compression=br"
    };


    simple-hydra.enable = true;
    simple-hydra.hostName = "hydra.tylerbenster.com";
    simple-hydra.useNginx = false;

    environment.systemPackages = with pkgs; [
      htop
      iotop
      vim
    ];

    networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  };
}