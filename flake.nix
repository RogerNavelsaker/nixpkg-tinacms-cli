{
  description = "Nix packaging scaffold for tinacms-cli";

  nixConfig = {
    extra-substituters = [ "https://cache.nixos.org" ];
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
