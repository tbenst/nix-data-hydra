# `simple-hydra` deployment with NixOps
---

`simple-hydra` is a NixOS module for easily setting up hydra. To
use it, simply add this to your `configuration.nix`:

```nix
{ pkgs, config, lib, ... }:
{

  # ...

  imports = [./simple-hydra];
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  simple-hydra = {
    enable = true;
    hostName = "example.org";
  };

  # ...

}
```

See `default.nix` for descriptions of other available options.

Once the server is running, you need to create an admin user on the
command line. For use with private repos, also need to generate an ssh key.

```bash
hydra-create-user USERNAME --full-name 'FULL NAME' --email-address 'EMAIL' --password 12345 --role admin
mkdir /var/lib/hydra/.ssh
ssh-keygen -t rsa -b 4096 -C "hydra@tylerbenster.com" -f /var/lib/hydra/.ssh/id_rsa
ssh-keygen -t rsa -b 4096 -C "hydra-queue-runner@tylerbenster.com" -f /var/lib/hydra/.ssh/runner_rsa
chown hydra:hydra /var/lib/hydra/.ssh/id_rsa*
chown hydra-queue-runner:hydra-queue-runner /var/lib/hydra/.ssh/runner_rsa*
```

## Nixops
To create (do once):
```
nixops create ./hydra-server.nix ./hydra-server-ec2.nix -d hydra-server-ec2
```

To deploy (to update config):
```
nixops deploy -d hydra-server-ec2
```

## Build slaves