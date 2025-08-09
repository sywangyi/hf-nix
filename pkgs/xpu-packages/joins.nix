{ xpuPackages, ... }:

final: prev: {
  # Intel oneAPI development environment for PyTorch compilation
  oneapi-torch-dev = final.callPackage (
    {
      lib,
      stdenv,
      gcc,
      cmake,
      pkg-config,
    }:
    let
      # Build only the most essential Intel packages for PyTorch
      essentialIntelPackages = lib.filter (pkg: pkg != null) [
        # Core DPC++ compiler package and its dependencies
        (
          if (lib.hasAttr "intel-oneapi-dpcpp-cpp-2025.2" final) then
            final."intel-oneapi-dpcpp-cpp-2025.2"
          else
            null
        )
        # Compiler runtime and shared components
        (
          if (lib.hasAttr "intel-oneapi-compiler-dpcpp-cpp-runtime-2025.2" final) then
            final."intel-oneapi-compiler-dpcpp-cpp-runtime-2025.2"
          else
            null
        )
        (
          if (lib.hasAttr "intel-oneapi-compiler-shared-2025.2" final) then
            final."intel-oneapi-compiler-shared-2025.2"
          else
            null
        )
        # MKL for math operations - most important for PyTorch
        (
          if (lib.hasAttr "intel-oneapi-mkl-core-2025.2" final) then
            final."intel-oneapi-mkl-core-2025.2"
          else
            null
        )
        (
          if (lib.hasAttr "intel-oneapi-mkl-devel-2025.2" final) then
            final."intel-oneapi-mkl-devel-2025.2"
          else
            null
        )
        # Common infrastructure packages
        (
          if (lib.hasAttr "intel-oneapi-common-licensing-2025.2" final) then
            final."intel-oneapi-common-licensing-2025.2"
          else
            null
        )
        (
          if (lib.hasAttr "intel-oneapi-common-vars" final) then
            final.intel-oneapi-common-vars
          else
            null
        )
        # TBB for threading
        (
          if (lib.hasAttr "intel-oneapi-tbb-2022.2" final) then
            final."intel-oneapi-tbb-2022.2"
          else
            null
        )
        (
          if (lib.hasAttr "intel-oneapi-tbb-devel-2022.2" final) then
            final."intel-oneapi-tbb-devel-2022.2"
          else
            null
        )
        # OpenMP
        (
          if (lib.hasAttr "intel-oneapi-openmp-2025.2" final) then
            final."intel-oneapi-openmp-2025.2"
          else
            null
        )
      ];

      # Standard development tools - always available
      standardPackages = [
        gcc
        cmake
        pkg-config
      ];

      # Combine essential Intel packages with standard tools
      allPackages = essentialIntelPackages ++ standardPackages;
    in
    stdenv.mkDerivation {
      name = "oneapi-torch-dev-2025.2.0";

      buildCommand = ''
        mkdir -p $out/bin

        # Copy all contents from each package, handling conflicts
        ${lib.concatMapStringsSep "\n" (pkg: ''
          if [ -d "${pkg}" ]; then
            cp -rf "${pkg}/"* "$out/" 2>/dev/null || true
            cp -rf "${pkg}/".* "$out/" 2>/dev/null || true
          fi
        '') allPackages}

        # Create convenience symlinks for Intel compilers in bin
        if [ -d "$out/oneapi/compiler/2025.2/bin" ]; then
          for tool in icx icpx dpcpp dpcpp-cl opencl-aot; do
            if [ -f "$out/oneapi/compiler/2025.2/bin/$tool" ]; then
              ln -sf "../oneapi/compiler/2025.2/bin/$tool" "$out/bin/$tool"
            fi
          done
        fi
      '';

      meta = with lib; {
        description = "Intel oneAPI development environment for PyTorch (copied files)";
        longDescription = ''
          A development package for PyTorch compilation with Intel optimizations.
          Uses copied files instead of symlinks to avoid path issues.
        '';
        license = licenses.free;
        platforms = platforms.linux;
        maintainers = [ ];
      };
    }
  ) { };
}
