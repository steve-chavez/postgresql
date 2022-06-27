# Depends on postgresql(requires pg_config),
# pg_config is not built from the PWD source but from the upsteam Nix package,
# it can be changed to depend on the PWD source but seems to be working fine so far
# https://github.com/postgres/postgres/blob/master/src/tools/pgindent/README
{ stdenv, postgresql, openssl, libkrb5, readline, zlib }:

stdenv.mkDerivation {
  name = "pg_bsd_ident";

  buildInputs = [ postgresql openssl libkrb5 readline zlib ];

  src = fetchGit {
    url = "https://git.postgresql.org/git/pg_bsd_indent.git";
  };

  installPhase = ''
    mkdir -p $out/bin
    mv pg_bsd_indent $out/bin/
  '';
}
