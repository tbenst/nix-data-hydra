only deploy nixops from lensman to avoid corrupting the SQLite database

## workflow for testing cachix
1. modify upload-to-cachix in hydra-server.nix
2. `nixops deploy -d hydra-server-ec2`
3. modify `madeup` in nix-data/jobsets/hello.nix and `git commit -am "test cachix" && git push` to trigger a hydra build
4. `nixops ssh -d hydra-server-ec2 hydra-server`
5. look at touched files in /tmp/
6. check logs, `journalctl -fx -u hydra-queue-runner`