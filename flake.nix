{
  description = "batcher development environment";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";

  };

  outputs = { self, nixpkgs, flake-utils, nix-filter }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.${system}.default = pkgs.mkShell {
          name = "batcher";

          buildInputs = with pkgs;
            with ocamlPackages;
            with nodePackages; [
              cmake
              glibc
              nixfmt
              npm
              yarn
              node2nix
              nodejs-18_x
            ];

          shellHook = ''
            alias lv="ligo version"
            alias lcc="ligo compile contract"
            alias lce="ligo compile expression"
            alias lcp="ligo compile parameter"
            alias lcs="ligo compile storage"
            alias build="make build"
            alias test="make test"
            alias run-ui="npm run start:ghostnet-ci"
            alias build-ui="npm run build:ghostnet-ci"
          '';

        };

        packages = let
          contract = pkgs.stdenv.mkDerivation {
            name = "batcher";
            src = ./.;

            buildInputs = with pkgs;
              with ocamlPackages; [
                cmake
                glibc
                nixfmt
              ];


            buildPhase = ''
              mkdir -p $out
              make build
            '';

          };

        in { inherit contract; };

        defaultPackage = self.packages.${system}.contract;

        apps = {
          contract =
            flake-utils.lib.mkApp { drv = self.packages.${system}.contract; };
        };

      });

}
