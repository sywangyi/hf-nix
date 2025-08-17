{ xpuPackages, dpcppVersion, ptiVersion, mklVersion, tbbVersion, ompVersion}:

final: prev: {
  # Intel oneAPI development environment for PyTorch compilation
  oneapi-torch-dev = final.callPackage (
    {
      lib,
      stdenv,
      gcc,
      cmake,
      pkg-config,
      rsync,
    }:
    let
      # Build only the most essential Intel packages for PyTorch
      essentialIntelPackages = [
        # Core DPC++ compiler package and its dependencies
        final."intel-oneapi-dpcpp-cpp-${dpcppVersion}"
        # Compiler runtime and shared components
        final."intel-oneapi-compiler-dpcpp-cpp-runtime-${dpcppVersion}"
        final."intel-oneapi-compiler-shared-${dpcppVersion}"
        final."intel-oneapi-compiler-shared-runtime-${dpcppVersion}"
        final."intel-oneapi-compiler-shared-common-${dpcppVersion}"
        final."intel-oneapi-compiler-dpcpp-cpp-common-${dpcppVersion}"
        # MKL for math operations - most important for PyTorch
        final."intel-oneapi-mkl-core-${mklVersion}"
        final."intel-oneapi-mkl-devel-${mklVersion}"
        # Common infrastructure packages
        #final."intel-oneapi-common-licensing-2025.2"
        final.intel-oneapi-common-vars
        # TBB for threading
        final."intel-oneapi-tbb-${tbbVersion}"
        final."intel-oneapi-tbb-devel-${tbbVersion}"
        # OpenMP
        final."intel-oneapi-openmp-${ompVersion}"
        # PTI (Profiling and Tracing Interface) - required for PyTorch compilation
        final."intel-pti-dev-${ptiVersion}"
        final."intel-pti-${ptiVersion}"
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
      name = "oneapi-torch-dev-${dpcppVersion}";
      nativeBuildInputs = [rsync];

      buildCommand = ''
        # Merge all top-level directories from every package into $out using rsync
        for pkg in ${lib.concatStringsSep " " (essentialIntelPackages ++ standardPackages)}; do
          for subdir in $(ls "$pkg"); do
            if [ -d "$pkg/$subdir" ]; then
              mkdir -p "$out/$subdir"
              rsync -a "$pkg/$subdir/" "$out/$subdir/"
            fi
          done
        done

        # Export environment variables for oneAPI tools
        export PATH="$out/oneapi/compiler/${dpcppVersion}/bin:$PATH"
        export LD_LIBRARY_PATH="$out/oneapi/compiler/${dpcppVersion}/lib:$LD_LIBRARY_PATH"
        export CPATH="$out/oneapi/compiler/${dpcppVersion}/include:$CPATH"
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

  oneapi-bintools-unwrapped = final.callPackage ./bintools-unwrapped.nix {
    oneapi-torch-dev = final.oneapi-torch-dev;
    dpcppVersion = dpcppVersion;
    ptiVersion = ptiVersion;
  };

  onednn-xpu = final.callPackage ./onednn-xpu.nix { 
    oneapi-torch-dev = final.oneapi-torch-dev;
    dpcppVersion = dpcppVersion;
  };
}
