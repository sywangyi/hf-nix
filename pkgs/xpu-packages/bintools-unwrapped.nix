{
  runCommand,
  oneapi-torch-dev,
  gcc,
  stdenv
}:

runCommand "oneapi-bintools-unwrapped" { preferLocalBuild = true; } ''
  mkdir -p $out
  ln -sf ${oneapi-torch-dev}/oneapi/compiler/latest/bin $out/bin
  ln -sf ${oneapi-torch-dev}/oneapi/compiler/latest/lib $out/lib
  ln -sf ${oneapi-torch-dev}/oneapi/compiler/latest/include $out/include

mkdir -p $out/nix-support
echo 'export SYCL_ROOT="${oneapi-torch-dev}/oneapi/compiler/latest"' >> $out/nix-support/setup-hook
echo 'export Pti_DIR="${oneapi-torch-dev}/oneapi/pti/latest/lib/cmake/pti"' >> $out/nix-support/setup-hook
#echo 'export MKLROOT="${oneapi-torch-dev}/oneapi/mkl/latest"' >> $out/nix-support/setup-hook
echo 'export SYCL_EXTRA_INCLUDE_DIRS="${gcc.cc}/include/c++/${gcc.version} ${stdenv.cc.libc_dev}/include ${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu"' >> $out/nix-support/setup-hook
echo 'export USE_ONEMKL_XPU=0' >> $out/nix-support/setup-hook
chmod 0444 $out/nix-support/setup-hook
''
