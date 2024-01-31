{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "hugo";
  nativeBuildInputs = with pkgs; [ hugo ];
}
