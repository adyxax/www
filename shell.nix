{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  name = "hugo";
  nativeBuildInputs = with pkgs; [ hugo ];
}
