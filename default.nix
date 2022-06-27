with import (builtins.fetchTarball {
  name = "2021-09-29";
  url = "https://github.com/NixOS/nixpkgs/archive/76b1e16c6659ccef7187ca69b287525fea133244.tar.gz";
  sha256 = "1vsahpcx80k2bgslspb0sa6j4bmhdx77sw6la455drqcrqhdqj6a";
}) {};
stdenv.mkDerivation rec {
  name = "pgDev";
  src = ./.;
  outputs = [ "out" "lib" "doc" "man" ];
  setOutputFlags = false; # $out retains configureFlags :-/
  NIX_CFLAGS_COMPILE = "-I${libxml2.dev}/include/libxml2";
  enableParallelBuilding = true;
  separateDebugInfo = true;
  installTargets = [ "install" ];
  buildFlags = [ "install" ];
  #patches = [
    #./patches/disable-resolve_symlinks-94.patch
    #./patches/less-is-more-96.patch
    #./patches/hardcode-pgxs-path-96.patch
  #];

  LC_ALL = "C";
  preConfigure = "CC=${stdenv.cc.targetPrefix}cc";
  disallowedReferences = [ stdenv.cc ];
  configureFlags = [
    "--sysconfdir=/etc"
    "--libdir=$(lib)/lib"
    "--with-system-tzdata=${tzdata}/share/zoneinfo"
    "--enable-debug"
  ];
  postConfigure =
    let path = "src/bin/pg_config/pg_config.c"; in
      ''
        # Hardcode the path to pgxs so pg_config returns the path in $out
        substituteInPlace "${path}" --replace HARDCODED_PGXS_PATH $out/lib
      '';
  buildInputs = [ readline zlib perl bison flex libxml2 ];
  #checkTarget = "check";
  doInstallCheck = false; # needs a running daemon?
}
