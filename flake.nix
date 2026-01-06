{
  description = "Nanofetch - Lightning fast Linux fetch tool in Zig";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zig,
      ...
    }:
    builtins.foldl' nixpkgs.lib.recursiveUpdate { } (
      builtins.map (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          zigPkg = zig.packages.${system}."0.15.2";
        in
        {
          devShells.${system}.default = pkgs.callPackage ./nix/dev-shell.nix {
            zig = zigPkg;
          };

          packages.${system} =
            let
              mkArgs = optimize: {
                inherit optimize;
                zig = zigPkg;
                revision = self.shortRev or self.dirtyShortRev or "dirty";
              };
            in
            rec {
              nanofetch-debug = pkgs.callPackage ./nix/package.nix (mkArgs "Debug");
              nanofetch-releasesafe = pkgs.callPackage ./nix/package.nix (mkArgs "ReleaseSafe");
              nanofetch-releasefast = pkgs.callPackage ./nix/package.nix (mkArgs "ReleaseFast");

              nanofetch = nanofetch-releasefast;
              default = nanofetch;
            };
        }
      ) (builtins.attrNames zig.packages)
    );
}
