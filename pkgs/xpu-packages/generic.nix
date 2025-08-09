{
  lib,
  autoPatchelfHook,
  callPackage,
  fetchurl,
  stdenv,
  rpmextract,
  rsync,
  xpuPackages,
  zlib,

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
    rpmextract
    rsync
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    stdenv.cc.cc.libgcc
    # Add zlib for libz.so.1 dependency
    zlib
  ] ++ (map (dep: xpuPackages.${dep}) filteredDeps);

  # Extract RPM packages using rpmextract
  unpackPhase = ''
    for src in $srcs; do
      rpmextract "$src"
    done
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    
    # Check if opt/intel exists and copy content
    if [ -d "opt/intel" ]; then
      cp -rT opt/intel $out
    elif [ -d "opt" ]; then
      cp -rT opt $out
    else
      # Fallback: copy everything if no opt directory found
      cp -r . $out/
    fi
    
    runHook postInstall
  '';

  # Stripping the binaries from the oneAPI packages might break them
  dontStrip = true;

  # Don't check for broken symlinks - Intel packages often have complex internal symlink structures
  preFixup = ''
    # Remove broken symlinks that point to Intel's "latest" structure
    find $out -type l ! -exec test -e {} \; -delete 2>/dev/null || true
  '';


  autoPatchelfIgnoreMissingDeps = [
    # oneAPI specific libraries that should come from driver/runtime
    "libOpenCL.so.1"
    "libze_loader.so.1"
    "libtbbmalloc.so.2"
    "libtbb.so.12"
    "libsycl.so.8" # Intel SYCL runtime library
    "libhwloc.so.15" # Hardware Locality library

    # Intel math and compiler libraries
    "libimf.so" # Intel Math Functions library
    "libsvml.so" # Intel Short Vector Math Library
    "libirng.so" # Intel Random Number Generator library
    "libintlc.so.5" # Intel Compiler library
    "libur_loader.so.0" # Unified Runtime loader
    "libffi.so" # Foreign Function Interface library
    "libumf.so.0" # Unified Memory Framework
    "libxptifw.so" # Intel XPU Profiling and Tracing Interface

    # System libraries that might not be available
    "libpython3.6m.so.1.0"
    "libpython3.7m.so.1.0"
    "libpython3.8.so.1.0"
    "libpython3.9.so.1.0"
  ];

  meta = with lib; {
    description = "Intel oneAPI package: ${pname}";
    homepage = "https://software.intel.com/oneapi";
    platforms = platforms.linux;
    license = licenses.unfree;
  };
}
