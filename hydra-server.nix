{
    network = {
    description = "Hydra server";
    enableRollback = true;
  };

  hydra-server = {
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
    nix.extraOptions = ''
      allowed-uris = https://github.com/tbenst/nixpkgs/archive/
    '';
    simple-hydra = {
      enable = true;
      hostName = "hydra.tylerbenster.com";
      useNginx = true;
      localBuilder.maxJobs = 2;
    };

    networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  };
}