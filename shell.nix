with import (builtins.fetchTarball {
  name = "2023-09-16";
  url = "https://github.com/NixOS/nixpkgs/archive/ae5b96f3ab6aabb60809ab78c2c99f8dd51ee678.tar.gz";
  sha256 = "11fpdcj5xrmmngq0z8gsc3axambqzvyqkfk23jn3qkx9a5x56xxk";
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

    [ ! -d build ] && ./configure --enable-cassert --enable-tap-tests --prefix ${pgBuildDir} --with-CC="ccache gcc" --with-perl --with-tcl --with-python

    echo 'Building pg...'

    make -j16 -s
    make install -j16 -s
  '';
  testScript = writeShellScriptBin "${prefix}-test" ''
    set -euo pipefail

    make check
  '';
  testWorldScript = writeShellScriptBin "${prefix}-test-world" ''
    set -euo pipefail

    make check-world
  '';
  # https://www.postgresql.org/docs/current/regress-tap.html
  # Example: pg-test-tap src/bin/psql/t/001_basic.pl
  tapTestScript = writeShellScriptBin "${prefix}-test-tap" ''
    set -euo pipefail

    directory="$(dirname $1)"
    filename="$(basename $1)"

    cd $directory && cd ..
    PROVE_TESTS="t/$filename" make check
  '';
  cleanScript = writeShellScriptBin "${prefix}-clean" ''
    rm -rf ${pgBuildDir}
  '';
  docsScript = writeShellScriptBin "${prefix}-serve-docs" ''
    set -euo pipefail
    make install-docs -j16
    cd ${pgBuildDir}/share/doc/html
    python -mSimpleHTTPServer 5050
  '';
  commitPatch = writeShellScriptBin "${prefix}-commit-patch" ''
    git format-patch -n HEAD^
  '';
in
mkShell {
  buildInputs = [
    readline zlib bison flex ctags ccache git icu pkg-config perl
    docbook_xml_dtd_45 libxml2 libxslt # for docs
    tcl
    python3Full
    perlPackages.IPCRun
    (callPackage ./nix/PerlTidy.nix {})
    (callPackage ./nix/pg_bsd_ident.nix {})
    (callPackage ./nix/pgScript.nix {inherit pgBuildDir;})
    styleScript
    checkStyleScript
    buildScript
    testScript
    testWorldScript
    cleanScript
    docsScript
    tapTestScript
    commitPatch
  ];
  shellHook = ''
    export HISTFILE=.history
    export OUR_SHELL="${bash}/bin/bash"
  '';
}
