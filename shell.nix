with import (builtins.fetchTarball {
  name = "2021-09-29";
  url = "https://github.com/NixOS/nixpkgs/archive/76b1e16c6659ccef7187ca69b287525fea133244.tar.gz";
  sha256 = "1vsahpcx80k2bgslspb0sa6j4bmhdx77sw6la455drqcrqhdqj6a";
}) {};
let
  prefix = "pg";
  pgBuildDir = "$PWD/build";
  styleScript = writeShellScriptBin "${prefix}-style" ''
    set -euo pipefail

    # will only work when using a different branch than master for development
    echo 'Running pgindent on changed files...'
    changed=$(${git}/bin/git diff-index --name-only HEAD -- '*.c')
    for x in $changed; do
      ./src/tools/pgindent/pgindent $x
    done

    # not producing reliable output yet
    # echo 'Running pgperltidy...'
    # ./src/tools/pgindent/pgperltidy
  '';
  checkStyleScript = writeShellScriptBin "${prefix}-check-style" ''
    set -euo pipefail

    ${styleScript}/bin/${prefix}-style

    ${git}/bin/git diff-index --exit-code HEAD -- '*.pl' '*.c'
  '';
  buildScript = writeShellScriptBin "${prefix}-build" ''
    set -euo pipefail

    [ ! -d build ] && ./configure --enable-cassert --prefix ${pgBuildDir} --with-CC="ccache gcc"

    echo 'Building pg...'

    make -j16 -s
    make install -j16 -s
  '';
  cleanScript = writeShellScriptBin "${prefix}-clean" ''
    rm -rf ${pgBuildDir}
  '';
in
mkShell {
  buildInputs = [
    readline zlib bison flex ctags ccache git icu pkg-config perl
    (callPackage ./nix/PerlTidy.nix {})
    (callPackage ./nix/pg_bsd_ident.nix {})
    (callPackage ./nix/pgScript.nix {inherit pgBuildDir;})
    styleScript
    checkStyleScript
    buildScript
    cleanScript
  ];
  shellHook = ''
    export HISTFILE=.history
  '';
}
