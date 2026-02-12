{lib}: let
  inherit (lib) all concatMapStrings concatStringsSep isAttrs isBool isInt isList isString;

  scalarNode = valueType: value: {
    _type = "ScalarNode";
    type = valueType;
    inherit value;
  };

  listNode = elements: {
    _type = "ListNode";
    inherit elements;
  };

  mapNode = entries: {
    _type = "MapNode";
    inherit entries;
  };

  isScalarNode = node:
    isAttrs node && node ? _type && node._type == "ScalarNode" && node ? type && node ? value;

  isListNode = node:
    isAttrs node && node ? _type && node._type == "ListNode" && node ? elements && isList node.elements;

  isMapNode = node:
    isAttrs node
    && node ? _type
    && node._type == "MapNode"
    && node ? entries
    && isList node.entries
    && all (entry: isAttrs entry && entry ? key && isString entry.key && entry ? value_node) node.entries;

  indentUnit = "  ";
  indentAtDepth = depth:
    if depth <= 0
    then ""
    else concatStringsSep "" (builtins.genList (_: indentUnit) depth);

  escapeString = value:
    builtins.toJSON value;

  scalarToYaml = node:
    if node.type == "string"
    then escapeString node.value
    else if node.type == "int"
    then builtins.toString node.value
    else if node.type == "bool"
    then
      if node.value
      then "true"
      else "false"
    else if node.type == "null"
    then "null"
    else throw "Unsupported scalar type: ${node.type}";

  renderNode = depth: node:
    if isScalarNode node
    then scalarToYaml node
    else if isListNode node
    then renderList depth node
    else if isMapNode node
    then renderMap depth node
    else throw "Unsupported AST node";

  renderMap = depth: node:
    if node.entries == []
    then "{}"
    else
      concatMapStrings (
        entry: let
          valueNode = entry.value_node;
          entryPrefix = "${indentAtDepth depth}${entry.key}:";
        in
          if isScalarNode valueNode
          then "${entryPrefix} ${renderNode depth valueNode}\n"
          else "${entryPrefix}\n${renderNode (depth + 1) valueNode}"
      )
      node.entries;

  renderList = depth: node:
    if node.elements == []
    then "[]"
    else
      concatMapStrings (
        element: let
          itemPrefix = "${indentAtDepth depth}-";
        in
          if isScalarNode element
          then "${itemPrefix} ${renderNode depth element}\n"
          else if isMapNode element
          then "${itemPrefix}\n${renderNode (depth + 1) element}"
          else if isListNode element
          then "${itemPrefix}\n${renderNode (depth + 1) element}"
          else throw "Unsupported list element node"
      )
      node.elements;

  normalizeScalar = value:
    if value == null
    then scalarNode "null" null
    else if isBool value
    then scalarNode "bool" value
    else if isInt value
    then scalarNode "int" value
    else if isString value
    then scalarNode "string" value
    else throw "Unsupported scalar value";

  orderedEntriesToMapNode = entries:
    if isList entries && all (entry: isAttrs entry && entry ? key && isString entry.key && entry ? value) entries
    then
      mapNode (
        map (entry: {
          key = entry.key;
          value_node = normalizeUnionValue entry.value;
        })
        entries
      )
    else throw "Ordered map entries must be a list of { key, value }";

  normalizeUnionValue = value:
    if isAttrs value && value ? _union && value ? value
    then normalizeUnionValue value.value
    else if isAttrs value && value ? _ordered_entries
    then orderedEntriesToMapNode value._ordered_entries
    else if isAttrs value && value ? _type
    then
      if isScalarNode value || isListNode value || isMapNode value
      then value
      else throw "Unsupported prebuilt AST node"
    else if isList value
    then listNode (map normalizeUnionValue value)
    else if isAttrs value
    then throw "Unordered attribute set detected; use {_ordered_entries = [ ... ]}"
    else normalizeScalar value;

  toYaml = value: let
    ast = normalizeUnionValue value;
    rendered = renderNode 0 ast;
  in
    if builtins.substring ((builtins.stringLength rendered) - 1) 1 rendered == "\n"
    then rendered
    else "${rendered}\n";

  nonNullEntry = key: value:
    if value == null
    then []
    else [{inherit key value;}];

  paneToEntries = paneAttrs:
    nonNullEntry "command" (paneAttrs.command or "")
    ++ nonNullEntry "shell" (paneAttrs.shell or null);

  windowToEntries = windowAttrs:
    nonNullEntry "layout" (windowAttrs.layout or null)
    ++ nonNullEntry "root" (windowAttrs.root or null)
    ++ nonNullEntry "focus" (windowAttrs.focus or null)
    ++ nonNullEntry "shell" (windowAttrs.shell or null)
    ++ nonNullEntry "pre" (windowAttrs.pre or null)
    ++ nonNullEntry "post" (windowAttrs.post or null)
    ++ nonNullEntry "panes" (
      map (paneAttrs: {_ordered_entries = paneToEntries paneAttrs;}) (
        if (windowAttrs.panes or null) == null
        then []
        else windowAttrs.panes
      )
    );

  sessionToOrderedEntries = sessionName: sessionAttrs:
    [
      {
        key = "name";
        value = sessionName;
      }
    ]
    ++ nonNullEntry "root" (sessionAttrs.root or null)
    ++ nonNullEntry "env" (
      if (sessionAttrs.env or null) == null
      then null
      else
        map (entry: {
          _ordered_entries = [
            {
              key = entry.name;
              value = entry.value;
            }
          ];
        })
        sessionAttrs.env
    )
    ++ nonNullEntry "pre" (sessionAttrs.pre or null)
    ++ nonNullEntry "post" (sessionAttrs.post or null)
    ++ nonNullEntry "tmux_options" (sessionAttrs.tmuxOptions or null)
    ++ [
      {
        key = "windows";
        value =
          map (window: {
            _ordered_entries = [
              {
                key = window.name;
                value = {
                  _ordered_entries = windowToEntries window;
                };
              }
            ];
          })
          (sessionAttrs.windows or []);
      }
    ];
in {
  inherit toYaml;

  generateSessionYaml = sessionName: sessionAttrs:
    toYaml {
      _ordered_entries = sessionToOrderedEntries sessionName sessionAttrs;
    };
}
