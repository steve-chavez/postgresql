with import (builtins.fetchTarball {
  name = "2023-09-16";
  url = "https://github.com/NixOS/nixpkgs/archive/ae5b96f3ab6aabb60809ab78c2c99f8dd51ee678.tar.gz";
  sha256 = "11fpdcj5xrmmngq0z8gsc3axambqzvyqkfk23jn3qkx9a5x56xxk";
}) {};
let
  prefix = "$PWD/build";
  styleScript = writeShellScriptBin "pg-style" ''
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
  checkStyleScript = writeShellScriptBin "pg-check-style" ''
    set -euo pipefail

    ${styleScript}/bin/pg-style

    ${git}/bin/git diff-index --exit-code HEAD -- '*.pl' '*.c'
  '';
  buildScript = writeShellScriptBin "pg-build" ''
    set -euo pipefail

    export OUR_SHELL="${bash}/bin/bash"

    [ ! -d build ] && ./configure CFLAGS="-ggdb -Og -g3 -fno-omit-frame-pointer" --enable-cassert --enable-tap-tests --prefix ${prefix} --with-CC="ccache gcc" --with-perl --with-tcl --with-python

    echo 'Building pg...'

    make -j16 -s
    make install -j16 -s
  '';
  testScript = writeShellScriptBin "pg-test" ''
    set -euo pipefail

    make check
  '';
  testWorldScript = writeShellScriptBin "pg-test-world" ''
    set -euo pipefail

    make check-world
  '';
  # https://www.postgresql.org/docs/current/regress-tap.html
  # Example: pg-test-tap src/bin/psql/t/001_basic.pl
  tapTestScript = writeShellScriptBin "pg-test-tap" ''
    set -euo pipefail

    directory="$(dirname $1)"
    filename="$(basename $1)"

    cd $directory && cd ..
    PROVE_TESTS="t/$filename" make check
  '';
  cleanScript = writeShellScriptBin "pg-clean" ''
    set -euo pipefail

    rm -rf ${prefix}
    make clean # needed to clean the source tree of some generated files
  '';
  docsScript = writeShellScriptBin "pg-serve-docs" ''
    set -euo pipefail

    make install-docs -j16
    cd ${prefix}/share/doc/html
    python -mSimpleHTTPServer 5050
  '';
  commitPatch = writeShellScriptBin "pg-commit-patch" ''
    git format-patch -n HEAD^
  '';
in
mkShell {
  buildInputs = [
    readline zlib bison flex ctags ccache git icu pkg-config perl
    docbook_xml_dtd_45 libxml2 libxslt # for docs
    valgrind
    tcl
    python3Full
    perlPackages.IPCRun
    (callPackage ./nix/PerlTidy.nix {})
    (callPackage ./nix/pg_bsd_ident.nix {})
    (callPackage ./nix/pgScript.nix {inherit prefix;})
    styleScript
    checkStyleScript
    buildScript
    testScript
    testWorldScript
    cleanScript
    docsScript
    tapTestScript
    commitPatch
    linuxPackages.perf
    linuxPackages.bpftrace
    linuxHeaders
  ];
  shellHook = ''
    export HISTFILE=.history
  '';
}
