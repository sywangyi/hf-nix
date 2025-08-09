{ xpuPackages, ... }:

{
  # Joined packages that combine multiple XPU components
  # For example, a full oneAPI development kit that includes compiler + libraries
  
  oneapi-basekit-full = xpuPackages.buildEnv {
    name = "oneapi-basekit-full";
    paths = with xpuPackages; [
      # Add oneAPI components here when they exist
      # intel-oneapi-compiler-dpcpp-cpp-runtime
      # intel-oneapi-mkl
      # intel-oneapi-tbb
      # intel-oneapi-ccl
      # intel-oneapi-dal
      # intel-oneapi-dpl
      # intel-oneapi-ipp
      # intel-oneapi-ippcp
    ];
  };
}
