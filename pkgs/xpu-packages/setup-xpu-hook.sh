#!/usr/bin/env bash

# Setup XPU environment variables and paths
# This hook configures the environment for Intel oneAPI Base Kit components

setupXpuEnvironment() {
    if [ -n "$XPU_PACKAGES_LIST" ]; then
        # Set up oneAPI environment variables
        for xpuPkg in $(echo "$XPU_PACKAGES_LIST" | tr ':' ' '); do
            if [ -d "$xpuPkg" ]; then
                # Add oneAPI binaries to PATH
                if [ -d "$xpuPkg/compiler/latest/linux/bin" ]; then
                    addToSearchPath PATH "$xpuPkg/compiler/latest/linux/bin"
                fi
                
                # Add oneAPI libraries to LD_LIBRARY_PATH
                if [ -d "$xpuPkg/compiler/latest/linux/lib" ]; then
                    addToSearchPath LD_LIBRARY_PATH "$xpuPkg/compiler/latest/linux/lib"
                fi
                
                # Add MKL libraries
                if [ -d "$xpuPkg/mkl/latest/lib/intel64" ]; then
                    addToSearchPath LD_LIBRARY_PATH "$xpuPkg/mkl/latest/lib/intel64"
                fi
                
                # Add TBB libraries
                if [ -d "$xpuPkg/tbb/latest/lib/intel64/gcc4.8" ]; then
                    addToSearchPath LD_LIBRARY_PATH "$xpuPkg/tbb/latest/lib/intel64/gcc4.8"
                fi
                
                # Set up environment variables
                export ONEAPI_ROOT="${ONEAPI_ROOT:-$xpuPkg}"
                export SYCL_ROOT="${SYCL_ROOT:-$xpuPkg}"
                export DPCPP_ROOT="${DPCPP_ROOT:-$xpuPkg}"
                
                if [ -d "$xpuPkg/mkl/latest" ]; then
                    export MKL_ROOT="${MKL_ROOT:-$xpuPkg/mkl/latest}"
                fi
                
                if [ -d "$xpuPkg/tbb/latest" ]; then
                    export TBB_ROOT="${TBB_ROOT:-$xpuPkg/tbb/latest}"
                fi
                
                if [ -d "$xpuPkg/ccl/latest" ]; then
                    export CCL_ROOT="${CCL_ROOT:-$xpuPkg/ccl/latest}"
                fi
                
                if [ -d "$xpuPkg/dal/latest" ]; then
                    export DAL_ROOT="${DAL_ROOT:-$xpuPkg/dal/latest}"
                fi
                
                if [ -d "$xpuPkg/dpl/latest" ]; then
                    export DPL_ROOT="${DPL_ROOT:-$xpuPkg/dpl/latest}"
                fi
                
                if [ -d "$xpuPkg/ipp/latest" ]; then
                    export IPP_ROOT="${IPP_ROOT:-$xpuPkg/ipp/latest}"
                fi
                
                if [ -d "$xpuPkg/ippcp/latest" ]; then
                    export IPPCP_ROOT="${IPPCP_ROOT:-$xpuPkg/ippcp/latest}"
                fi
            fi
        done
    fi
}

# Run the setup function
setupXpuEnvironment
