{
  lib,
  autoPatchelfHook,
  callPackage,
  fetchurl,
  stdenv,
  rpmextract,
  rsync,
  writeText,
  xpuPackages,

  pname,
  version,

  # List of string-typed dependencies.
  deps,

  # List of derivations that must be merged.
  components,
}:

let
  # Filter out system dependencies that we don't want to include
  filteredDeps = lib.filter (
    dep:
    !builtins.elem dep [
      # Add any oneAPI-specific system dependencies to filter out
      "intel-opencl"
      "intel-level-zero-gpu"
      "intel-media-va-driver-non-free"
      "libdrm2"
      "libc6"
      "libgcc-s1"
      "libstdc++6"
    ]
  ) deps;
  srcs = map (component: fetchurl { inherit (component) url sha256; }) components;
in
stdenv.mkDerivation rec {
  inherit pname version srcs;

  nativeBuildInputs = [
    autoPatchelfHook
    xpuPackages.markForXpuRootHook or null
    rpmextract
    rsync
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    stdenv.cc.cc.libgcc
  ] ++ (map (dep: xpuPackages.${dep}) filteredDeps);

  # Extract RPM packages
  unpackPhase = ''
    for src in $srcs; do
      rpmextract "$src"
    done
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    
    # Copy oneAPI installation
    if [ -d opt/intel ]; then
      cp -rT opt/intel $out
    fi
    
    # Some packages might use different paths
    if [ -d usr ]; then
      cp -rT usr $out
    fi
    
    runHook postInstall
  '';

  # Stripping the binaries from the oneAPI packages might break them
  dontStrip = true;

  autoPatchelfIgnoreMissingDeps = [
    # oneAPI specific libraries that should come from driver/runtime
    "libOpenCL.so.1"
    "libze_loader.so.1"
    "libtbbmalloc.so.2"
    "libtbb.so.12"
    
    # System libraries that might not be available
    "libpython3.6m.so.1.0"
    "libpython3.7m.so.1.0"
    "libpython3.8.so.1.0"
    "libpython3.9.so.1.0"
  ];

  # Set up environment variables for oneAPI
  setupHook = writeText "setup-hook.sh" ''
    export ONEAPI_ROOT=@out@
    export SYCL_ROOT=@out@
    export DPCPP_ROOT=@out@
    export MKL_ROOT=@out@/mkl/latest
    export TBB_ROOT=@out@/tbb/latest
    export CCL_ROOT=@out@/ccl/latest
    export DAL_ROOT=@out@/dal/latest
    export DPL_ROOT=@out@/dpl/latest
    export IPPCP_ROOT=@out@/ippcp/latest
    export IPP_ROOT=@out@/ipp/latest
    
    # Add oneAPI binaries to PATH
    if [ -d "@out@/compiler/latest/linux/bin" ]; then
      addToSearchPath PATH "@out@/compiler/latest/linux/bin"
    fi
    
    # Add oneAPI libraries to library path
    if [ -d "@out@/compiler/latest/linux/lib" ]; then
      addToSearchPath LD_LIBRARY_PATH "@out@/compiler/latest/linux/lib"
    fi
    
    # Add MKL libraries
    if [ -d "@out@/mkl/latest/lib/intel64" ]; then
      addToSearchPath LD_LIBRARY_PATH "@out@/mkl/latest/lib/intel64"
    fi
  '';
}
