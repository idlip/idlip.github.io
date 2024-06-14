with import <nixpkgs> {};
pkgs.mkShell {

  nativeBuildInputs = [ pkgs.bashInteractive ];


  buildInputs = with pkgs; [
    python3
    ];

  # add script to rebuild?
  shellHook = ''
  Site can be loaded
  '';
}
