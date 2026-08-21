with import <nixpkgs> {};
pkgs.mkShell {

  buildInputs = with pkgs; [
    # pagefind
    hugo harper vale
    just librsvg
    # go-org
    treefmt pre-commit prettier taplo htmlhint gotmplfmt
  ];

  shellHook = ''
    # Command to Run
  '';
}
