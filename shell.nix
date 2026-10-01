with import <nixpkgs> {};
pkgs.mkShell {

  buildInputs = with pkgs; [
    # pagefind
    # hugo
    harper vale
    just librsvg
    # go-org
    pre-commit prettier
    static-web-server
  ];

  shellHook = ''
    # Command to Run
  '';
}
