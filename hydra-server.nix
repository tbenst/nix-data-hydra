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

    simple-hydra.enable = true;
    simple-hydra.hostName = "hydra.tylerbenster.com";
    simple-hydra.useNginx = false;

    # networking.firewall.allowedTCPPorts = [ 3000 ];
  };
}