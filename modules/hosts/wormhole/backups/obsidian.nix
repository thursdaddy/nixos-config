_: {
  configurations.nixos.wormhole.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.mine.base) user;

      backupScript = pkgs.writeShellApplication {
        name = "backup-obsidian-git";
        runtimeInputs = with pkgs; [
          git
          coreutils
          findutils
          openssh
        ];
        text = ''
          # Cleanup any syncthing conflicts
          find ./ -type f -iname "*.sync-conflict*" -print0 | xargs -0 rm -vf

          CHANGES=$(git status --porcelain)
          UNPUSHED=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "0")
          if [[ -z "$CHANGES" ]] && [[ "$UNPUSHED" -eq 0 ]]; then
            echo "No changes.."
            git pull --rebase
            exit 0
          fi

          echo "Syncing: $UNPUSHED pending commits, local changes:
               $([[ -n "$CHANGES" ]] && echo "Yes" || echo "No")"

          # Only commit if there are actually changes in the working tree
          if [[ -n "$CHANGES" ]]; then
            git add .
            git commit -m "Automated backup: $(date '+%Y-%m-%d %H:%M:%S')"
          fi

          # Pull and push
          git pull --rebase
          git push
        '';
      };

    in
    {
      systemd =
        let
          backup = lib.thurs.mkBackupService {
            inherit pkgs;
            name = "notes";
            extraEnv = {
              HOMELAB_BACKUP_ENABLE = "true";
              HOMELAB_BACKUP_PATH = "${user.homeDir}/notes";
              HOMELAB_BACKUP_RETENTION_PERIOD = "5";
            };
          };
        in
        {
          services = {
            backup-notes = backup.service;

            backup-obsidian-git = {
              description = "Automated Git backup for Obsidian notes";
              onFailure = [ "gotify-backup-failure@%N.service" ];
              serviceConfig = {
                Type = "oneshot";
                User = "${user.name}";
                Group = "${user.name}";
                ExecStart = "${lib.getExe backupScript}";
                WorkingDirectory = "${user.homeDir}/notes/obsidian/thurs";
              };
              environment = {
                GIT_TERMINAL_PROMPT = "0";
              };
            };
          };

          timers = {
            backup-notes = backup.timer;

            backup-obsidian-git = {
              description = "Run obsidian daily backup";
              timerConfig = {
                OnCalendar = "daily";
                Persistent = true;
              };
              wantedBy = [ "timers.target" ];
            };
          };
        };

      environment.etc =
        let
          alloyJournalFile = lib.thurs.mkAlloyJournal {
            name = "backup_notes_files";
            serviceName = "backup-notes";
          };
          alloyJournalGit = lib.thurs.mkAlloyJournal {
            name = "backup_obsidian_git";
            serviceName = "backup-obsidian-git";
          };
        in
        {
          "${alloyJournalFile.name}" = alloyJournalFile.value;
          "${alloyJournalGit.name}" = alloyJournalGit.value;
        };
    };
}
