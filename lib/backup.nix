{ lib }:
{
  mkBackupService =
    {
      pkgs,
      name,
      preStart ? "",
      postStart ? "",
      extraPackages ? [ ],
      extraEnv ? { },
    }:
    {
      service = {
        description = "Backups for ${name}";
        environment = extraEnv;
        path = extraPackages;
        onFailure = [ "gotify-failure@%N.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.homelab-backup} --backup --name ${name} --json";
        };
        inherit preStart postStart;
      };

      timer = {
        description = "Schedule backups for ${name}";
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "30m";
        };
        wantedBy = [ "timers.target" ];
      };
    };
}
