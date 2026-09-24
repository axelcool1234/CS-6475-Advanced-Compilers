{
  description = "CS 6475 MLIR dataflow analysis (LLVM 23)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          llvm = pkgs.llvmPackages_23;
          pluginSuffix = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
        in
        rec {
          known-bits = pkgs.stdenv.mkDerivation {
            pname = "known-bits";
            version = "0.1.0";
            src = nixpkgs.lib.cleanSourceWith {
              src = ./.;
              filter =
                path: type:
                let
                  name = builtins.baseNameOf path;
                  isBuildDirectory =
                    type == "directory"
                    && (name == "build" || nixpkgs.lib.hasPrefix "build-" name);
                in
                nixpkgs.lib.cleanSourceFilter path type && !isBuildDirectory;
            };

            nativeBuildInputs = [
              pkgs.cmake
              pkgs.makeWrapper
              pkgs.ninja
              llvm.mlir
            ];

            cmakeFlags = [
              "-DLLVM_DIR=${llvm.llvm.dev}/lib/cmake/llvm"
              "-DMLIR_DIR=${llvm.mlir.dev}/lib/cmake/mlir"
            ];

            doCheck = true;
            checkPhase = ''
              runHook preCheck
              ctest --output-on-failure
              runHook postCheck
            '';

            postInstall = ''
              makeWrapper ${llvm.mlir}/bin/mlir-opt $out/bin/known-bits \
                --add-flags "--load-pass-plugin=$out/lib/KnownBits${pluginSuffix}" \
                --add-flags "--pass-pipeline='builtin.module(known-bits)'"
            '';
          };

          default = known-bits;
        }
      );

      checks = forAllSystems (system: {
        build-and-test = self.packages.${system}.default;
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          llvm = pkgs.llvmPackages_23;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.cmake
              pkgs.ninja
              llvm.clang
              llvm.llvm
              llvm.mlir
            ];

            LLVM_DIR = "${llvm.llvm.dev}/lib/cmake/llvm";
            MLIR_DIR = "${llvm.mlir.dev}/lib/cmake/mlir";
          };
        }
      );
    };
}
