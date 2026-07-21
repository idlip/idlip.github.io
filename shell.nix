with import <nixpkgs> {};
pkgs.mkShell {

  buildInputs = with pkgs; [
    # pagefind
    hugo harper vale
    just librsvg
    # go-org
  ];

  shellHook = ''
    # Command to Run
  '';
}
