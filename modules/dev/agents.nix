_: {
  flake.modules.generic.dev =
    {
      config,
      lib,
      pkgs,
      options,
      ...
    }:
    let
      cfg = config.mine.dev.agents;
    in
    {
      options.mine.dev.agents = lib.mkOption {
        description = "Agentic coding tools";
        default = { };
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable agentic coding tools";
            };
            crush = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable Crush";
            };
            antigravity = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable Google Antigravity";
            };
            claude-code = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable Claude Code";
            };
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          nixpkgs.config.allowUnfreePredicate = pkg: cfg.crush && builtins.elem (lib.getName pkg) [ "crush" ];

          environment.systemPackages =
            (lib.optional cfg.crush pkgs.unstable.crush)
            ++ (lib.optionals cfg.antigravity [
              pkgs.unstable.antigravity-cli
              pkgs.python3
            ])
            ++ (lib.optionals cfg.claude-code [
              pkgs.unstable.claude-code
              pkgs.python3
            ]);
        })
        (lib.mkIf cfg.enable (
          lib.optionalAttrs (options ? systemd) {
            systemd.user.tmpfiles.rules = [
              "d %h/.gemini/config 0700 - - -"
              "L+ %h/.gemini/config/rules - - - - %h/dev/homelab/agent/.agents/rules"
              "L+ %h/.gemini/config/skills - - - - %h/dev/homelab/agent/.agents/skills"
              "L+ %h/.gemini/config/plugins - - - - %h/dev/homelab/agent/.agents/plugins"
              "L+ %h/.gemini/config/subagents - - - - %h/dev/homelab/agent/.agents/subagents"
              "L+ %h/.gemini/config/hooks.json - - - - %h/dev/homelab/agent/.agents/hooks.json"
              "L+ %h/.gemini/config/AGENTS.md - - - - %h/dev/homelab/agent/.agents/AGENTS.md"
              "L+ %h/.gemini/config/mcp_config.json - - - - %h/dev/homelab/agent/mcp.json"
            ];
          }
        ))
        (lib.mkIf (cfg.enable && cfg.claude-code) (
          lib.optionalAttrs (options ? systemd) {
            systemd.user.tmpfiles.rules = [
              "d %h/.claude 0700 - - -"
              "L+ %h/.claude/CLAUDE.md - - - - %h/dev/homelab/agent/claude/CLAUDE.md"
              "L+ %h/.claude/settings.json - - - - %h/dev/homelab/agent/claude/settings.json"
            ];
          }
        ))
        (lib.mkIf (cfg.enable && cfg.claude-code) (
          lib.optionalAttrs (!(options ? systemd)) {
            system.activationScripts.postActivation.text = ''
              mkdir -p "${config.mine.base.user.homeDir}/.claude"
              ln -sf "${config.mine.base.user.homeDir}/dev/homelab/agent/claude/CLAUDE.md" "${config.mine.base.user.homeDir}/.claude/CLAUDE.md"
              ln -sf "${config.mine.base.user.homeDir}/dev/homelab/agent/claude/settings.json" "${config.mine.base.user.homeDir}/.claude/settings.json"
              chown -h ${config.mine.base.user.name}:staff "${config.mine.base.user.homeDir}/.claude" "${config.mine.base.user.homeDir}/.claude/CLAUDE.md" "${config.mine.base.user.homeDir}/.claude/settings.json"
              if [ -f "${config.mine.base.user.homeDir}/dev/homelab/agent/claude/install.py" ]; then
                sudo -H -u ${config.mine.base.user.name} env PATH="${lib.makeBinPath [ pkgs.unstable.claude-code ]}:$PATH" \
                  ${pkgs.python3}/bin/python3 "${config.mine.base.user.homeDir}/dev/homelab/agent/claude/install.py"
              fi
            '';
          }
        ))
        (lib.mkIf cfg.enable (
          lib.optionalAttrs (!(options ? systemd)) {
            system.activationScripts.postActivation.text = ''
              mkdir -p "${config.mine.base.user.homeDir}/.gemini/config"
              rm -rf "${config.mine.base.user.homeDir}/.gemini/config/rules" "${config.mine.base.user.homeDir}/.gemini/config/skills" "${config.mine.base.user.homeDir}/.gemini/config/plugins" "${config.mine.base.user.homeDir}/.gemini/config/plugins.json" "${config.mine.base.user.homeDir}/.gemini/config/skills.json"
              ln -sfn "${config.mine.base.user.homeDir}/dev/homelab/agent/.agents/rules" "${config.mine.base.user.homeDir}/.gemini/config/rules"
              ln -sfn "${config.mine.base.user.homeDir}/dev/homelab/agent/.agents/skills" "${config.mine.base.user.homeDir}/.gemini/config/skills"
              ln -sfn "${config.mine.base.user.homeDir}/dev/homelab/agent/.agents/plugins" "${config.mine.base.user.homeDir}/.gemini/config/plugins"
              ln -sfn "${config.mine.base.user.homeDir}/dev/homelab/agent/.agents/subagents" "${config.mine.base.user.homeDir}/.gemini/config/subagents"
              ln -sf "${config.mine.base.user.homeDir}/dev/homelab/agent/.agents/hooks.json" "${config.mine.base.user.homeDir}/.gemini/config/hooks.json"
              ln -sf "${config.mine.base.user.homeDir}/dev/homelab/agent/.agents/AGENTS.md" "${config.mine.base.user.homeDir}/.gemini/config/AGENTS.md"
              ln -sf "${config.mine.base.user.homeDir}/dev/homelab/agent/mcp.json" "${config.mine.base.user.homeDir}/.gemini/config/mcp_config.json"
              chown -R ${config.mine.base.user.name}:staff "${config.mine.base.user.homeDir}/.gemini"
            '';
          }
        ))
      ];
    };
}
