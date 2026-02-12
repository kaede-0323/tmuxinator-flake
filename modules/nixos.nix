{
  config,
  lib,
  pkgs,
  ...
}: let
  yaml = import ./lib-yaml.nix {inherit lib;};
  tmuxinatorConfig = config.tmuxinator or {};
  sessions = tmuxinatorConfig.sessions or {};
in {
  options.tmuxinator.sessions = lib.mkOption {
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

  config = {
    environment.systemPackages = lib.mkAfter [pkgs.tmuxinator];
    environment.etc = builtins.listToAttrs (
      lib.mapAttrsToList (sessionName: sessionAttrs: {
        name = "tmuxinator/${sessionName}.yml";
        value.text = yaml.generateSessionYaml sessionName sessionAttrs;
      })
      sessions
    );
  };
}
