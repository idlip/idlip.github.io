with import <nixpkgs> {};
let
  prettierGoTemplate = pkgs.writeShellScriptBin "prettier-gotmpl" ''
    exec ${pkgs.prettier}/bin/prettier \
      --plugin=${pkgs.prettier-plugin-go-template}/lib/node_modules/prettier-plugin-go-template/lib/index.js \
      "$@"
  '';
in
pkgs.mkShell {

  buildInputs = with pkgs; [
    # pagefind
    hugo harper vale
    just librsvg
    # go-org
    treefmt pre-commit prettier taplo htmlhint
    prettierGoTemplate
  ];

  shellHook = ''
    # Command to Run
  '';
}
