{ xpuPackages, ... }:

final: prev: {
  # Intel oneAPI development environment for PyTorch compilation
  oneapi-torch-dev = final.callPackage (
    {
      lib,
      symlinkJoin,
      makeWrapper,
      writeShellScriptBin,
      gcc,
      cmake,
      pkg-config,
    }:
    let
      # Create a setup script
      setupScript = writeShellScriptBin "setup-oneapi-torch-env.sh" ''
        #!/bin/bash
        echo "Intel oneAPI PyTorch Development Environment"
        echo "Note: Using available packages from nixpkgs"
        
        # Set basic environment variables
        export ONEAPI_TORCH_DEV_ROOT="$out"
        echo "Environment activated!"
      '';

      # Build only the most essential Intel packages for PyTorch
      essentialIntelPackages = lib.filter (pkg: pkg != null) [
        # Just the core MKL for math operations - most important for PyTorch
        (
          if (lib.hasAttr "intel-oneapi-mkl-core-2025.2" final) then
            final."intel-oneapi-mkl-core-2025.2"
          else
            null
        )
        # Common licensing - required
        (
          if (lib.hasAttr "intel-oneapi-common-licensing" final) then
            final.intel-oneapi-common-licensing
          else
            null
        )
        # Intel DPC++ compiler and runtime for SYCL/OneAPI development
        (
          if (lib.hasAttr "intel-oneapi-compiler-dpcpp-cpp-2025.2" final) then
            final."intel-oneapi-compiler-dpcpp-cpp-2025.2"
          else
            null
        )
        (
          if (lib.hasAttr "intel-oneapi-dpcpp-cpp-2025.2" final) then
            final."intel-oneapi-dpcpp-cpp-2025.2"
          else
            null
        )
        (
          if (lib.hasAttr "intel-oneapi-compiler-dpcpp-cpp-common-2025.2" final) then
            final."intel-oneapi-compiler-dpcpp-cpp-common-2025.2"
          else
            null
        )
      ];

      # Standard development tools - always available
      standardPackages = [
        gcc
        cmake
        pkg-config
        setupScript
      ];

      # Combine essential Intel packages with standard tools
      availablePackages = essentialIntelPackages ++ standardPackages;
    in
    symlinkJoin {
      name = "oneapi-torch-dev-2025.2.0";
      paths = availablePackages;

      nativeBuildInputs = [ makeWrapper ];

      # Keep postBuild empty for now
      postBuild = "";

      meta = with lib; {
        description = "Intel oneAPI development environment for PyTorch (using available packages)";
        longDescription = ''
          A development package for PyTorch compilation with Intel optimizations.
          Uses available Intel oneAPI packages from nixpkgs or falls back to standard tools.
        '';
        license = licenses.free;
        platforms = platforms.linux;
        maintainers = [ ];
      };
    }
  ) { };
}
