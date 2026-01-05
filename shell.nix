with import <nixpkgs> {};
pkgs.mkShell {

  buildInputs = with pkgs; [
    hugo pagefind harper vale
  ];

  shellHook = ''
    # Command to Run
  '';
}
