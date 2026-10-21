{
  description = "vita: urbit desk";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # kernel dev files (/lib/default-agent, /lib/strandio, /mar/bill, ...)
    urbit = {
      url = "github:urbit/urbit/408k-2";
      flake = false;
    };
    # %landscape dev files (/sur/docket, /sur/treaty, /mar/docket-0, ...)
    landscape = {
      url = "github:tloncorp/landscape/46c6ed8738082b6a94558710b1e3619befa83057";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, urbit, landscape }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.runCommand "vita-desk" { } ''
          mkdir $out
          cp -rL --no-preserve=mode ${urbit}/pkg/base-dev/. $out/
          cp -rL --no-preserve=mode ${landscape}/desk-dev/. $out/
          # treaty is not part of landscape's desk-dev
          install -Dm644 ${landscape}/desk/sur/treaty.hoon $out/sur/treaty.hoon
          cp -rL --no-preserve=mode ${./vita}/. $out/
        '';

        # frontend build output, to be globbed onto a ship
        glob = pkgs.buildNpmPackage {
          pname = "vita-glob";
          version = "2.1.0";
          src = ./frontend;
          npmDepsHash = "sha256-9Rrf7YL6Ucrr7Q8APWa/bM2tgd+SSbmjxFNCTSj7q5E=";
          installPhase = ''
            runHook preInstall
            cp -r dist $out
            runHook postInstall
          '';
        };
      });
    };
}
