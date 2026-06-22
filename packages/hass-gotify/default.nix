{
  fetchFromGitHub,
  buildHomeAssistantComponent,
  requests,
}:

buildHomeAssistantComponent rec {
  owner = "1RandomDev";
  domain = "gotify";
  version = "1.0.0";

  src = fetchFromGitHub {
    inherit owner;
    repo = "homeassistant-gotify";
    rev = "v${version}";
    hash = "sha256-EBuYiXGA+hNwEC6Zfxj/VN8rqpwoI7ocWwlcjvToCTc=";
  };

  dependencies = [
    requests
  ];
}
