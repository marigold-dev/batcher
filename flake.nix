{
  description = "batcher development environment";

  nixConfig.bash-promt = "batcher-nix-develop$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-filter = {
      url = "github:numtide/nix-filter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ligolang = {
      url = "gitlab:ligolang/ligo/0.48.1";
      flake = false;
    };

    tezos.url = "github:marigold-dev/tezos-nix";
    tezos.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, flake-utils, nix-filter, tezos, ligolang }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        devShells.${system}.default  = pkgs.mkShell {
          name = "batcher";
          buildInputs = with pkgs; with ocamlPackages; [
            cmake
            glibc
            nixfmt
            tezos
            ligolang
          ];
          shellHook = ''
            alias lv="ligo version"
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
          ligo-compiler-version=0.49.0;
          tezos-protocol="jakarta";
          contract = pkgs.stdenv.mkDerivation {
            name = "batcher";
            src = ./.;
            buildDir = "$src/build";


            buildInputs = with pkgs; with ocamlPackages; [
              cmake
              glibc
              ligo
              nixfmt
              #tezos
              #ligolang
            ];

            buildPhase = ''
              mkdir -p $out
              ligo compile contract $src/batcher/batcher.mligo -e  main -s cameligo -o $out/batcher.tz
              INITSTORAGE=$(<$src/batcher/storage/storage.mligo)
              ligo compile storage $src/slip/batcher.mligo "$INITSTORAGE" -s cameligo -e main -o $out/batcher-storage.tz
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
