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

        bunDeps = pkgs.stdenv.mkDerivation {
          name = "tinacms-cli-bun-deps";
          inherit src;
          nativeBuildInputs = [ pkgs.bun pkgs.cacert ];
          buildPhase = ''
            export BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache
            bun install --production --ignore-scripts
          '';
          installPhase = ''
            mkdir -p $out
            if [ -d node_modules ]; then
              cp -r node_modules $out/
            fi
          '';
          dontFixup = true;
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = "sha256-KDgvibF3h2lvtGo+HenjIxaLX1dr28aoJD7O1NHNWTk=";
        };

        tinacms-cli = pkgs.stdenv.mkDerivation {
          pname = "tinacms-cli";
          inherit version src;
          nativeBuildInputs = [ pkgs.bun pkgs.makeWrapper ];
          
          buildPhase = ''
            if [ -d ${bunDeps}/node_modules ]; then
              cp -r ${bunDeps}/node_modules ./
              chmod -R +w node_modules
            fi
          '';

          installPhase = ''
            mkdir -p $out/libexec/tinacms-cli $out/bin
            cp -r . $out/libexec/tinacms-cli
            
            makeWrapper ${pkgs.bun}/bin/bun $out/bin/tinacms \
              --add-flags "$out/libexec/tinacms-cli/bin/tinacms"
          '';

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
