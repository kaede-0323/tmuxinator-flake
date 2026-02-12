{
  lib,
  pkgs,
  ...
}:
with lib; let
  # pane YAML
  generatePaneYaml = paneAttrs: let
    cmd = paneAttrs.command or "";
    shell = paneAttrs.shell or null;
  in
    if shell != null
    then "    - shell: " + shell + "\n      command: " + cmd
    else "    - " + cmd;

  # window YAML
  generateWindowYaml = attrs: let
    layout = attrs.layout or null;
    root = attrs.root or null;
    focus =
      if attrs.focus == true
      then true
      else null;
    startDir = attrs.startDir or null;
    pre = attrs.pre or [];
    post = attrs.post or [];
    panes = attrs.panes or [];
    shell = attrs.shell or null;
  in
    builtins.concatStringsSep "\n" (
      concatLists [
        (
          if layout != null
          then ["  layout: ${layout}"]
          else []
        )
        (
          if root != null
          then ["  root: ${root}"]
          else []
        )
        (
          if focus != null
          then ["  focus: true"]
          else []
        )
        (
          if startDir != null
          then ["  start_dir: ${startDir}"]
          else []
        )
        (
          if shell != null
          then ["  shell: ${shell}"]
          else []
        )
        (
          if builtins.length pre > 0
          then ["  pre: ${builtins.concatStringsSep ", " pre}"]
          else []
        )
        (
          if builtins.length post > 0
          then ["  post: ${builtins.concatStringsSep ", " post}"]
          else []
        )
        (["  panes:"] ++ map generatePaneYaml panes)
      ]
    );

  # session YAML
  generateSessionYaml = sessionAttrs: let
    root = sessionAttrs.root or null;
    env = sessionAttrs.env or {};
    pre = sessionAttrs.pre or [];
    post = sessionAttrs.post or [];
    tmuxOptions = sessionAttrs.tmux_options or [];
    windows = sessionAttrs.windows or {};
  in
    builtins.concatStringsSep "\n" (
      concatLists [
        (
          if root != null
          then ["root: ${root}"]
          else []
        )
        (
          if builtins.length (attrNames env) > 0
          then ["env:"] ++ mapAttrsToList (k: v: "  ${k}: ${v}") env
          else []
        )
        (
          if builtins.length pre > 0
          then ["pre:  ${builtins.concatStringsSep ", " pre}"]
          else []
        )
        (
          if builtins.length post > 0
          then ["post:  ${builtins.concatStringsSep ", " post}"]
          else []
        )
        (
          if builtins.length tmuxOptions > 0
          then ["tmux_options:  ${builtins.concatStringsSep ", " tmuxOptions}"]
          else []
        )
        concatLists
        (mapAttrsToList (windowName: attrs: ["${windowName}:"] ++ generateWindowYaml attrs) windows)
      ]
    );
in {
  options.tmuxinator = {
    sessions = mkOption {
      type = attrsOf (attrsOf (attrsOf (union {
        layout = str;
        panes = listOf (attrsOf {
          command = str;
          shell = str;
        });
        startDir = str;
        root = str;
        shell = str;
        focus = bool;
        pre = listOf str;
        post = listOf str;
      })));
      default = {};
      description = ''
        Tmuxinator sessions full definition.
        Structure: sessions.<session> = { root?, env?, pre?, post?, tmux_options?, windows = { <window> = { layout?, root?, focus?, panes?, shell?, startDir?, pre?, post? } } }
        Panes can be: [ { command = "...", shell = "..." } ]
      '';
    };
  };

  config = {
    home.packages =
      (config.home.packages or [])
      ++ [
        pkgs.tmuxinator
      ];
    home.file = builtins.listToAttrs (
      mapAttrsToList (sessionName: sessionAttrs: {
        name = ".tmuxinator/${sessionName}.yml";
        text = generateSessionYaml sessionAttrs;
      })
      config.tmuxinator.sessions
    );
  };
}
