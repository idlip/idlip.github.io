with import <nixpkgs> {};
pkgs.mkShell {

  buildInputs = with pkgs; [
    hugo pagefind
  ];

  shellHook = ''
    # Command to Run
  '';
}
