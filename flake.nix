{
  description = "Nix packaging scaffold for tinacms-cli";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://rogernavelsaker.cachix.org"
      "https://nacosolutions.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "rogernavelsaker.cachix.org-1:n1DtzMNhA9Rz4Kg3xlXOi/KceULu8VrMbs9WXyMFQNQ="
      "nacosolutions.cachix.org-1:JzCiW2CLcuLXtwOVAg3SlSK/kpqWbfSFEVenyKVUlug="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        version = "2.5.1";

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@tinacms/cli/-/cli-${version}.tgz";
          hash = "sha256-Ly4fK9un7EDSFZYIRBaNcUX+ihZLC6aFabntDKi/MH8=";
        };

        tinacms-cli = pkgs.buildNpmPackage {
          pname = "tinacms-cli";
          inherit version src;
          postPatch = ''
            cp ${./package-lock.json} package-lock.json
          '';
          npmDepsFetcherVersion = 2;
          npmDepsHash = "sha256-ELm/HeiO1F/4cBXzZJnB8TZdvG1Yq9p9Bo4nrJhIPuM=";
          npmFlags = [
            "--ignore-scripts"
            "--legacy-peer-deps"
          ];
          dontNpmBuild = true;

          meta = with pkgs.lib; {
            description = "TinaCMS CLI";
            homepage = "https://tina.io";
            license = licenses.asl20;
            mainProgram = "tinacms";
          };
        };
      in
      {
        packages = {
          inherit tinacms-cli;
          default = tinacms-cli;
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nix-update ];
        };
      }
    );
}
