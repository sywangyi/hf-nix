#!/usr/bin/env bash

# Mark packages for XPU root setup
# This hook ensures that XPU packages are properly identified for environment setup

if [ -n "${xpuPackages-}" ]; then
    export XPU_PACKAGES_LIST="${XPU_PACKAGES_LIST:+$XPU_PACKAGES_LIST:}$out"
fi
