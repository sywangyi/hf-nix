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
      essentialIntelPackages = [
        # Core DPC++ compiler package and its dependencies
        final."intel-oneapi-dpcpp-cpp-2025.2"
        # Compiler runtime and shared components
        final."intel-oneapi-compiler-dpcpp-cpp-runtime-2025.2"
        final."intel-oneapi-compiler-shared-2025.2"
        final."intel-oneapi-compiler-shared-runtime-2025.2"
        final."intel-oneapi-compiler-shared-common-2025.2"
        final."intel-oneapi-compiler-dpcpp-cpp-common-2025.2"
        # MKL for math operations - most important for PyTorch
        final."intel-oneapi-mkl-core-2025.2"
        final."intel-oneapi-mkl-devel-2025.2"
        # Common infrastructure packages
        final."intel-oneapi-common-licensing-2025.2"
        final.intel-oneapi-common-vars
        # TBB for threading
        final."intel-oneapi-tbb-2022.2"
        final."intel-oneapi-tbb-devel-2022.2"
        # OpenMP
        final."intel-oneapi-openmp-2025.2"
        # PTI (Profiling and Tracing Interface) - required for PyTorch compilation
        final."intel-pti-dev-0.12"
        final."intel-pti-0.12"
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

        # Copy all contents from each package, handling conflicts and permissions
        ${lib.concatMapStringsSep "\n" (pkg: ''
          if [ -d "${pkg}" ]; then
            # Set write permissions on target directories before copying
            find "$out" -type d -exec chmod u+w {} \; 2>/dev/null || true
            cp -r "${pkg}/"* "$out/" 2>/dev/null || true
            cp -r "${pkg}/".* "$out/" 2>/dev/null || true
          fi
        '') essentialIntelPackages}

        # Copy standard packages
        ${lib.concatMapStringsSep "\n" (pkg: ''
          if [ -d "${pkg}" ]; then
            find "$out" -type d -exec chmod u+w {} \; 2>/dev/null || true
            cp -r "${pkg}/"* "$out/" 2>/dev/null || true
            cp -r "${pkg}/".* "$out/" 2>/dev/null || true
          fi
        '') standardPackages}
        # Create wrapper scripts for Intel compilers instead of direct symlinks
        if [ -d "$out/oneapi/compiler/2025.2/bin" ]; then
          for tool in icx icpx dpcpp dpcpp-cl opencl-aot; do
            if [ -f "$out/oneapi/compiler/2025.2/bin/$tool" ]; then
              cat > "$out/bin/$tool" << 'WRAPPER_EOF'
#!/bin/bash
# Wrapper script for Intel compiler
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ONEAPI_ROOT=$(dirname "$(dirname "$(readlink -f "$0")")")/oneapi
export PATH="$ONEAPI_ROOT/compiler/2025.2/bin:$PATH"
export LD_LIBRARY_PATH="$ONEAPI_ROOT/compiler/2025.2/lib:$LD_LIBRARY_PATH"
export CPATH="$ONEAPI_ROOT/compiler/2025.2/include:$CPATH"
exec "$ONEAPI_ROOT/compiler/2025.2/bin/TOOL_NAME" "$@"
WRAPPER_EOF
              # Replace TOOL_NAME with the actual tool name
              sed -i "s/TOOL_NAME/$tool/g" "$out/bin/$tool"
              chmod +x "$out/bin/$tool"
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

  onednn-xpu = final.callPackage ./onednn-xpu.nix { 
    oneapi-torch-dev = final.oneapi-torch-dev;
  };
}
