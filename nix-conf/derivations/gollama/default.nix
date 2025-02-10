{
  lib,
  fetchFromGitHub,
  buildGoModule,
  versionCheckHook,
}:

buildGoModule rec {
  pname = "gollama";
  version = "1.28.10";

  src = fetchFromGitHub {
    owner = "sammcj";
    repo = "gollama";
    rev = "8a84d6a628df366a57104ebedaddf87aec908a4a";
    hash = "sha256-njqstopsiyS2vNQ7MV/nND8cnA+EZvGyiVHBaxXcEoM=";
  };

  vendorHash = "sha256-RxPnpj7jVcjP/V0XFfLqkUQhh3j1wGnCFztsX3BXO3Y=";

  doCheck = false;

  ldFlags = [
    "-s"
    "-w"
  ];

  # FIXME: error when running `env -i gollama`:
  # "Error initializing logging: $HOME is not defined"
  doInstallCheck = false;
  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  versionCheckProgramArg = [ "-v" ];
}
