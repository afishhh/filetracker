{ pkgs, config, ... }:

{
  boot.isContainer = true;
  networking.useDHCP = false;
  networking.hostName = "filetracker";

  services.filetracker = {
    enable = true;

    # These options default to the specified values:
    # listenAddress = "0.0.0.0";
    # port = 9999;
    # openFirewall = true;

    ensureFiles = {
      "/sandbox/compiler-gcc.10_2_1.tar.gz" = pkgs.fetchurl {
        url = "https://downloads.sio2project.mimuw.edu.pl/sandboxes/compiler-gcc.10_2_1.tar.gz";
        hash = "sha256-+QO7/ZqLWRvFCF9KdVqrZ6ZsBB96bkRgYVUUezvAf8A=";
      };
      "/sandbox/proot-sandbox_amd64.tar.gz" = pkgs.fetchurl {
        url = "https://downloads.sio2project.mimuw.edu.pl/sandboxes/proot-sandbox_amd64.tar.gz";
        hash = "sha256-u6CSak326pAa7amYqYuHIqFu1VppItOXjFyFZgpf39w=";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    htop
    # For the `filetracker` CLI
    pkgs.filetracker
  ];

  imports = [
    ./module.nix
  ];
}
