{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    typescript.url = "github:Microsoft/TypeScript";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    typescript,
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
        {
          defaultPackage = pkgs.nodejs-16_x;
          devShell = nixpkgs.mkShell {
            buildInputs = [
              pkgs.nodejs-16_x
              pkgs.typescript
            ];
          };
           packages = {
            "batcher-liquidity-bot" = {
              buildInputs = [
                pkgs.nodejs-16_x
                pkgs.typescript
              ];
              sources = [ ./. ];
              outputs = {
                nix = {
                  build = "npm run build";
                  install = "npm install";
                  source = "npm pack";
                };
              };
              };
            };
        });
}
