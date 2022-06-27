with import (builtins.fetchTarball {
  name = "2023-09-16";
  url = "https://github.com/NixOS/nixpkgs/archive/ae5b96f3ab6aabb60809ab78c2c99f8dd51ee678.tar.gz";
  sha256 = "11fpdcj5xrmmngq0z8gsc3axambqzvyqkfk23jn3qkx9a5x56xxk";
}) {};
let
  prefix = "$PWD/build";
  styleScript = writeShellScriptBin "pg-style" ''
    set -euo pipefail

    cd ${prefix}/src/tools/pg_bsd_indent/
    make -j16 -s

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
  exports = ''
    export OUR_SHELL="${bash}/bin/bash"
    export CC="ccache gcc"
  '';
  buildScript = writeShellScriptBin "pg-build" ''
    set -euo pipefail

    ${exports}

    mkdir -p ${prefix}

    cd ${prefix}

    [ ! -d ${prefix} ] && ../configure --enable-cassert --enable-tap-tests --with-perl --with-tcl --with-python --prefix ${prefix}

    echo 'Building pg...'

    make -j16 -s
    make install -j16 -s
  '';
  buildExtensionScript = writeShellScriptBin "pg-build-extension" ''
    set -euo pipefail

    ${buildScript}/bin/pg-build

    cd ${prefix}

    cd contrib/$1

    echo "Building $1 extension ..."

    make -j16 -s
    make install -j16 -s
  '';
  testScript = writeShellScriptBin "pg-test" ''
    set -euo pipefail

    ${exports}

    cd ${prefix}

    if [ "$#" -eq 0 ]; then
        make check
    else
        # care ful with this as it looks like tests have dependencies so running a single one could fail
        # Join all arguments with spaces.
        tests="$*"
        make check-tests TESTS="$tests"
    fi
  '';
  testExtensionScript = writeShellScriptBin "pg-test-extension" ''
    set -euo pipefail

    ${exports}

    cd ${prefix}

    cd contrib/$1

    make check
  '';
  testWorldScript = writeShellScriptBin "pg-test-world" ''
    set -euo pipefail

    ${exports}

    cd ${prefix}

    make check-world
  '';
  # https://www.postgresql.org/docs/current/regress-tap.html
  # Example: pg-test-tap src/bin/psql/t/001_basic.pl
  tapTestScript = writeShellScriptBin "pg-test-tap" ''
    set -euo pipefail

    ${exports}

    cd ${prefix}

    directory="$(dirname $1)"
    filename="$(basename $1)"

    cd $directory && cd ..
    PROVE_TESTS="t/$filename" make check
  '';
  cleanScript = writeShellScriptBin "pg-clean" ''
    set -euo pipefail

    ${exports}

    cd ${prefix}

    make distclean # needed to clean the source tree of some generated files

    cd ..

    rm -rf ${prefix}

    echo "if you run into missing header files, make sure to run `git clean -xdf` too"
  '';
  docsScript = writeShellScriptBin "pg-serve-docs" ''
    set -euo pipefail

    ${exports}

    cd ${prefix}

    make install-docs -j16
    cd ${prefix}/share/doc/html
    python -mSimpleHTTPServer 5050
  '';
  commitPatch = writeShellScriptBin "pg-commit-patch" ''
    git format-patch -n HEAD^
  '';
  ctagsScript = writeShellScriptBin "pg-ctags" ''
    ./src/tools/make_ctags
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
    (callPackage ./nix/pgScript.nix {inherit prefix;})
    styleScript
    checkStyleScript
    buildScript
    buildExtensionScript
    testExtensionScript
    testWorldScript
    cleanScript
    docsScript
    tapTestScript
    commitPatch
    ctagsScript
  ];
  shellHook = ''
    export HISTFILE=.history
  '';
}
