# Starts a fast pg
{ writeShellScriptBin, pgBuildDir } :

let
  script = ''
    set -e

    export PATH=${pgBuildDir}/bin:"$PATH"

    tmpdir="$(mktemp -d)"

    export PGDATA="$tmpdir"
    export PGHOST="$tmpdir"
    export PGUSER=postgres
    export PGDATABASE=postgres

    trap 'pg_ctl stop -m i && rm -rf "$tmpdir"' sigint sigterm exit

    PGTZ=UTC initdb --no-locale --encoding=UTF8 --nosync -U "$PGUSER"

    options="-F -c listen_addresses=\"\" -k $PGDATA"

    pg_ctl start -o "$options"

    "$@"
  '';
in
writeShellScriptBin "with-pg" script
