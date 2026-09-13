{
  lib,
  pkgs,
  ...
}: let
  extensions = [
    "txt"
    "md"
    "markdown"
    "json"
    "yaml"
    "yml"
    "toml"
    "py"
    "js"
    "ts"
    "rs"
    "go"
    "sh"
    "bash"
    "zsh"
    "css"
  ];
in {
  home.activation.defaultApps = lib.hm.dag.entryAfter ["writeBoundary"] (
    lib.concatMapStringsSep "\n"
    (extension: "${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .${extension} all")
    extensions
  );
}
