{
  description = "batcher development environment";

  nixConfig = {
    extra-substituters = ["https://tezos.nix-cache.workers.dev"];
    extra-trusted-public-keys = ["tezos-nix-cache.marigold.dev-1:4nS7FPPQPKJIaNQcbwzN6m7kylv16UCWWgjeZZr2wXA="];
    bash-promt = "batcher-nix$ ";
  };

  inputs = {

    nixpkgs.url = "github:anmonteiro/nix-overlays";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";

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
        };
        ligo = pkgs.callPackage ./nix/ligo.nix { };
      in {
        devShells.${system}.default  = pkgs.mkShell {
          name = "batcher";
          buildInputs = with pkgs; with ocamlPackages; [
            cmake
            glibc
            nixfmt
            ligo
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
            ];

            buildPhase = ''
              mkdir -p $out
              ligo compile contract $src/batcher/batcher.mligo -e  main -s cameligo -o $out/batcher.tz
              INITSTORAGE=$(<$src/batcher/storage/intial_storage.mligo)
              ligo compile storage $src/batcher/batcher.mligo "$INITSTORAGE" -s cameligo -e main -o $out/batcher-storage.tz
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
