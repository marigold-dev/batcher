{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "ligo";
  version = "0.50.0";
  jobid = "2896100663";

  executable = fetchurl {
    name = "ligo";
    url = "https://gitlab.com/ligolang/ligo/-/jobs/2959700000/artifacts/raw/ligo";
    sha256 = "sha256-YO3/NgRCXJi6XFgXL1f5J7zmRjBpFb7Kft0vn6SnjTQ=";
    executable = true;
  };

  phases = [ "installPhase" ]; # Removes all phases except installPhase

  installPhase =
    "\n    mkdir -p $out/bin\n    cp ${executable} $out/bin/ligo\n  ";
  }
