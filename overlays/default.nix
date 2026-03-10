let
  files = builtins.removeAttrs (builtins.readDir ./.) [ "default.nix" ];
in
map (name: import ./${name}) (builtins.attrNames files)
