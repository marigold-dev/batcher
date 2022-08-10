{
  description = "0-slip development environment";

  nixConfig.bash-promt = "0slip-nix-develop$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-filter = {
      url = "github:numtide/nix-filter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tezos.url = "github:marigold-dev/tezos-nix";
    tezos.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };

  };

  outputs = { self, nixpkgs, flake-utils, nix-filter, tezos }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          #overlays = [ tezos.overlays.default ];
        };
      in {
        devShells.${system}.default  = pkgs.mkShell {
          name = "0-slip";
          buildInputs = with pkgs; with ocamlPackages; [
            cmake
            glibc
            ligo
            nixfmt
          ];
          shellHook = ''
            alias ligodock="docker run --rm -v \"$PWD\":\"$PWD\" -w \"$PWD\" ligolang/ligo:0.47.0"
            alias lcc="ligo compile contract"
            alias lce="ligo compile expression"
            alias lcp="ligo compile parameter"
            alias lcs="ligo compile storage"
            alias build="./do build contract"
            alias dryrun="./do dryrun contract"
            alias deploy="./do deploy contract"
          '';

        };

        packages = let
          contract = pkgs.stdenv.mkDerivation {
            name = "0slip";
            src = ./.;
            buildDir = "$src/build";


            buildInputs = with pkgs; [ ligo ];

            installPhase = ''
              mkdir -p $out
              ligo compile contract $src/slip/0slip.mligo -e  main -s cameligo -o $out/0slip.tz
              INITSTORAGE=$(<$src/slip/storage/storage.mligo)
              ligo compile storage $src/slip/0slip.mligo "$INITSTORAGE" -s cameligo -e main -o $out/0slip-storage.tz
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
