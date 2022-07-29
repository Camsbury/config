{pkgs}:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "duka";
  version = "master";
  src = pkgs.fetchFromGitHub rec {
    owner = "giuse88";
    repo = "${pname}";
    rev = "master";
    sha256 = "1xk87x2c7s6b1qfd6lblsipwp4py8572vgc1rcmg6j6pqc9asy4v";
  };
  propagatedBuildInputs = [
    pkgs.python3Packages.requests
  ];
  doCheck = false;
}
