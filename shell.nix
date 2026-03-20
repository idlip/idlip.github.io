with import <nixpkgs> {};
pkgs.mkShell {

  buildInputs = with pkgs; [
    # pagefind
    hugo harper vale
    # go-org
  ];

  shellHook = ''
    # Command to Run
  '';
}
