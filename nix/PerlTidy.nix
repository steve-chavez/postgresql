# If we run the latest PerlTidy, we get a lot of changes across .pl files
# So we install the exact 20170521 version as specified in the pgindent/README:

#2) Install perltidy.  Please be sure it is version 20170521 (older and newer
#  versions make different formatting choices, and we want consistency).
#  You can get the correct version from
#  https://cpan.metacpan.org/authors/id/S/SH/SHANCOCK/
#  To install, follow the usual install process for a Perl module
#  ("man perlmodinstall" explains it).  Or, if you have cpan installed,
#  this should work:
#  cpan SHANCOCK/Perl-Tidy-20170521.tar.gz
{ lib, fetchurl, perl, perlPackages }:

perlPackages.buildPerlPackage rec {
  pname = "Perl-Tidy";
  version = "20170521";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SH/SHANCOCK/Perl-Tidy-20170521.tar.gz";
    sha256 = "sha256-AbPxeME6wkFUoO4qYtPOPynPzGsyewswIQlOADCepNo=";
  };
  meta = {
    description = "Indent and reformat perl scripts";
    license = lib.licenses.gpl2Plus;
    mainProgram = "perltidy";
  };
}
