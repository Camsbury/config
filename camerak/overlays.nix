self: super: {
  python3 = super.python3.override {
    packageOverrides = python-self: python-super: {
      hid =
        python-super.buildPythonPackage rec {
          pname = "hid";
          version = "1.0.4";

          src = python-super.fetchPypi {
            inherit pname version;
            sha256 = "1h9zi0kyicy3na1azfsgb57ywxa8p62bq146pb44ncvsyf1066zn";
          };

          doCheck = false;

          # propagatedBuildInputs = [
          #   self.hidapi
          # ];
        };
      pyusb =
        python-super.buildPythonPackage rec {
          pname = "pyusb";
          version = "1.1.1";

          src = python-super.fetchPypi {
            inherit pname version;
            sha256 = "0f7wzb7yqhkp65xmnsjdqa4z4c61bavf1al91gvayn6f2vcrli3x";
          };

          doCheck = false;

          propagatedBuildInputs = with python-self; [
            setuptools_scm
          ];
        };
      milc = python-super.milc.overrideAttrs (oldAttrs: {
        src = python-super.fetchPypi {
          pname = "milc";
          version = "1.4.2";
          sha256 = "1z962v8f1kkwp6vr45pqm5a20vrm7r9q7j7qc000mc4n66gg3cn6";
        };
        propagatedBuildInputs = with python-self; [
          appdirs
          argcomplete
          halo
          spinners
        ];
      });
      qmk =
        python-super.buildPythonPackage rec {
          pname = "qmk";
          version = "0.0.51";

          src = python-super.fetchPypi {
            inherit pname version;
            sha256 = "16kb7idsm56lwfjmpx79m80csqj9d3cqddixhawr5pz1rl4z5vpg";
          };

          doCheck = false;

          propagatedBuildInputs = with python-self; [
            dotty-dict
            flake8
            hid
            hjson
            jsonschema
            milc
            nose2
            pygments
            pyusb
            yapf
          ];
        };
    };
  };
}
