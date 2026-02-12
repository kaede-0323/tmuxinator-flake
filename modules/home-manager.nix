{
  config,
  lib,
  pkgs,
  ...
}: let
  yaml = import ./lib-yaml.nix {inherit lib;};
in {
  options.programs.tmuxinator = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable tmuxinator support in Home-manager";
    };

    sessions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          root = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          env = lib.mkOption {
            type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
            default = null;
          };
          pre = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
          };
          post = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
          };
          tmuxOptions = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
          };
          windows = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                layout = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                root = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                focus = lib.mkOption {
                  type = lib.types.nullOr lib.types.bool;
                  default = null;
                };
                shell = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                pre = lib.mkOption {
                  type = lib.types.nullOr (lib.types.listOf lib.types.str);
                  default = null;
                };
                post = lib.mkOption {
                  type = lib.types.nullOr (lib.types.listOf lib.types.str);
                  default = null;
                };
                panes = lib.mkOption {
                  type = lib.types.nullOr (lib.types.listOf (lib.types.attrsOf (lib.types.nullOr lib.types.str)));
                  default = null;
                };
              };
            });
            default = {};
          };
        };
      });
      default = {};
    };
  };

  config = lib.mkIf config.programs.tmuxinator.enable {
    home.packages = lib.mkAfter [pkgs.tmuxinator];
    home.file = builtins.listToAttrs (
      lib.mapAttrsToList (sessionName: sessionAttrs: {
        name = ".tmuxinator/${sessionName}.yml";
        value.text = yaml.generateSessionYaml sessionName sessionAttrs;
      })
      config.programs.tmuxinator.sessions
    );
  };
}
