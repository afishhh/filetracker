{ pkgs, lib, config, ... }:

{
  options.services.filetracker = {
    enable = lib.mkEnableOption "Filetracker Server";

    package = lib.mkPackageOptionMD pkgs "Filetracker" {
      default = [ "python38Packages" "filetracker" ];
    };

    listenAddress = lib.mkOption {
      default = "0.0.0.0";
      description = "The address that filetracker-server will listen on";
      type = lib.types.str;
    };

    port = lib.mkOption {
      default = 9999;
      description = "The port that filetracker-server will listen on";
      type = lib.types.port;
    };

    openFirewall = lib.mkOption {
      default = true;
      description = "Whether to open the provided port in the firewall";
      type = lib.types.bool;
    };

    ensureFiles = lib.mkOption {
      default = { };
      description = "Files that should be added to filetracker after start";
      type = lib.types.attrsOf lib.types.path;
    };
  };

  config =
    let
      cfg = config.services.filetracker;
      python = cfg.package.pythonModule;

      createEnsureService = remotePath: localPath:
        let
          systemdEscapedPath = builtins.replaceStrings [ "/" ] [ "-" ] (lib.removePrefix "/" remotePath);
          serviceName = "filetracker-put-${systemdEscapedPath}";
        in
        lib.nameValuePair serviceName {
          enable = true;
          description = "Filetracker ensure ${remotePath}";
          after = [ "filetracker.service" ];
          wantedBy = [ "filetracker.service" ];

          environment = {
            REMOTE_PATH = remotePath;
            SOURCE_PATH = localPath;
            FILETRACKER_MEDIA_ROOT = "/var/lib/filetracker";
            FILETRACKER_URL = "http://${cfg.listenAddress}:${builtins.toString cfg.port}";
          };

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${python.withPackages (pp: [ pp.filetracker ])}/bin/python3 ${./filetracker-ensure.py}";
          };
        };
    in
    lib.mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

      users.extraUsers.filetracker = {
        isSystemUser = true;
        group = "filetracker";
      };
      users.extraGroups.filetracker = {};

      systemd.services = {
        filetracker = {
          enable = true;
          description = "Filetracker Server";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          environment = {
            PYTHONPATH = "${python.pkgs.makePythonPath [ cfg.package ]}";
          };

          serviceConfig = {
            Type = "simple";
            ReadOnlyPaths = "/";
            ReadWritePaths = [ "/tmp" ];
            ExecStart =
              ''
                ${cfg.package}/bin/filetracker-server \
                  -d /var/lib/filetracker \
                  -l ${lib.escapeShellArg cfg.listenAddress} \
                  -p ${builtins.toString cfg.port} \
                  -D
              '';
            StateDirectory = "filetracker";
            User = "filetracker";
            Group = "filetracker";
          };
        };
      } // (lib.mapAttrs' createEnsureService cfg.ensureFiles);
    };
}
