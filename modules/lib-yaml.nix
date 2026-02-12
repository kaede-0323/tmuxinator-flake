{ lib }:
let
  inherit (lib) attrNames concatLists mapAttrsToList;

  generatePaneYaml = paneAttrs:
    let
      command = paneAttrs.command or "";
      shell = paneAttrs.shell or null;
    in
    if shell == null then
      "    - ${command}"
    else
      "    - shell: ${shell}\n      command: ${command}";

  generateWindowYaml = windowAttrs:
    let
      layout = windowAttrs.layout or null;
      root = windowAttrs.root or null;
      focus = windowAttrs.focus or null;
      startDir = windowAttrs.startDir or null;
      shell = windowAttrs.shell or null;
      pre = windowAttrs.pre or null;
      post = windowAttrs.post or null;
      panes = windowAttrs.panes or [];
    in
    builtins.concatStringsSep "\n" (
      concatLists [
        (if layout == null then [] else [ "  layout: ${layout}" ])
        (if root == null then [] else [ "  root: ${root}" ])
        (if focus == null then [] else [ "  focus: ${if focus then "true" else "false"}" ])
        (if startDir == null then [] else [ "  start_dir: ${startDir}" ])
        (if shell == null then [] else [ "  shell: ${shell}" ])
        (if pre == null then [] else [ "  pre: ${builtins.concatStringsSep ", " pre}" ])
        (if post == null then [] else [ "  post: ${builtins.concatStringsSep ", " post}" ])
        ([ "  panes:" ] ++ map generatePaneYaml panes)
      ]
    );

  generateSessionYaml = sessionAttrs:
    let
      root = sessionAttrs.root or null;
      env = sessionAttrs.env or null;
      pre = sessionAttrs.pre or null;
      post = sessionAttrs.post or null;
      tmuxOptions = sessionAttrs.tmuxOptions or null;
      windows = sessionAttrs.windows or {};
    in
    builtins.concatStringsSep "\n" (
      concatLists [
        (if root == null then [] else [ "root: ${root}" ])
        (
          if env == null || builtins.length (attrNames env) == 0 then
            []
          else
            [ "env:" ] ++ mapAttrsToList (k: v: "  ${k}: ${v}") env
        )
        (if pre == null then [] else [ "pre: ${builtins.concatStringsSep ", " pre}" ])
        (if post == null then [] else [ "post: ${builtins.concatStringsSep ", " post}" ])
        (if tmuxOptions == null then [] else [ "tmux_options: ${builtins.concatStringsSep ", " tmuxOptions}" ])
        (concatLists (mapAttrsToList (windowName: attrs: [ "${windowName}:" ] ++ [ generateWindowYaml attrs ]) windows))
      ]
    );
in {
  inherit generatePaneYaml generateWindowYaml generateSessionYaml;
}
