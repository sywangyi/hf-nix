{ stdenv, fetchFromGitHub, cmake, ninja, python3, gcc, oneapi-torch-dev, lib, writeShellScriptBin, writeText }:

stdenv.mkDerivation rec {
  env.CXX = "icpx";
  env.CC = "icx";
  env.CXXFLAGS = "-isystem${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/clang/21/include -I${stdenv.cc.libc_dev}/include -I${gcc.cc}/include/c++/${gcc.version}  -I${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu";
  env.CFLAGS = "-I${stdenv.cc.libc_dev}/include";
  env.LDFLAGS =
    "-L${stdenv.cc}/lib -L${stdenv.cc}/lib64 -L${stdenv.cc.libc}/lib -L${stdenv.cc.libc}/lib64 -L${stdenv.cc.libc}/usr/lib -L${stdenv.cc.libc_dev}/lib -L${stdenv.cc.libc_dev}/lib64 -L${stdenv.cc.libc_dev}/usr/lib -L${stdenv.cc}/lib/gcc/${stdenv.cc.targetPrefix}/${stdenv.cc.version} -L${stdenv.cc}/lib/gcc/${stdenv.cc.targetPrefix} -L${stdenv.cc}/lib/gcc -L${stdenv.cc}/libexec/gcc/${stdenv.cc.targetPrefix}/${stdenv.cc.version}" +
    (if stdenv.cc ? cc && stdenv.cc.cc ? libgcc then " -L${stdenv.cc.cc.libgcc}/lib" else "") +
    " -L/nix/store/qnwxpk0in4bm43q2qnykvkjxa9qhqd0z-gcc-14.3.0/lib/gcc/x86_64-unknown-linux-gnu/14.3.0 -L/nix/store/xvqbvva4djgyascjsnki6354422n4msk-gcc-14.3.0/lib/gcc/x86_64-unknown-linux-gnu/14.3.0" +
    " -L/nix/store/6vzcxjxa2wlh3p9f5nhbk62bl3q313ri-gcc-14.3.0-lib/lib";
  pname = "onednn-xpu";
  version = "3.8.1";

  src = fetchFromGitHub {
    owner = "oneapi-src";
    repo = "oneDNN";
    rev = "v3.8.1";
    sha256 = "sha256-x4leRd0xPFUygjAv/D125CIXn7lYSyzUKsd9IDh/vCc="; # 首次 build 用 fakeSha256，build 后替换
  };

  preConfigure = ''
    echo "==== crt debug ===="
    find ${stdenv.cc.libc} ${stdenv.cc.libc_dev} -name 'crt1.o' -o -name 'crti.o' -o -name 'crtbegin.o'
    echo "==== end crt debug ===="
    echo "==== gcc path debug ===="
    echo "gcc = ${gcc.cc}/lib/gcc/x86_64-unknown-linux-gnu/${gcc.version}/include"
    ls -l ${gcc}/include/c++ || true
    echo "==== end gcc path debug ===="
  '';



  nativeBuildInputs = [
    (writeShellScriptBin "icx" ''
      exec ${oneapi-torch-dev}/oneapi/compiler/2025.2/bin/icx "$@"
    '')
    (writeShellScriptBin "icpx" ''
      exec ${oneapi-torch-dev}/oneapi/compiler/2025.2/bin/icpx "$@"
    '')
    (writeShellScriptBin "g++" ''
      exec ${gcc.cc}/bin/g++ \
        -nostdinc -nostdinc++ \
        -I${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/clang/21/include \
        -isystem${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/clang/21/include \
        -isysroot ${stdenv.cc.libc_dev} \
        -isystem${stdenv.cc.libc_dev}/include \
        -isystem${stdenv.cc.libc}/include \
        -isystem${stdenv.cc.libc}/usr/include \
        -I${gcc.cc}/include/c++/${gcc.version} \
        -I${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu \
        -I${gcc.cc}/lib/gcc/x86_64-unknown-linux-gnu/${gcc.version}/include \
        -msse -mmmx -march=native \
        "$@"
    '')
    cmake
    ninja
    python3
  ];
  buildInputs = [
    oneapi-torch-dev
    stdenv.cc.libc
    stdenv.cc.libc_dev
    stdenv.cc
    gcc.cc
  ] ++ lib.optional (stdenv.cc ? cc && stdenv.cc.cc ? libgcc) stdenv.cc.cc.libgcc;

  # Write a CMake toolchain file to set CMAKE_CXX_FLAGS_SYCL with all needed flags
  syclToolchainFile = writeText "sycl-toolchain.cmake" ''
  set(CMAKE_C_FLAGS_INIT "-B${stdenv.cc.libc}/lib -B${stdenv.cc.libc_dev}/lib -B${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/crt -I${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/clang/21/include -isystem${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/clang/21/include -isysroot ${stdenv.cc.libc_dev} -isystem${stdenv.cc.libc_dev}/include -msse -mmmx -march=native")
  set(CMAKE_CXX_FLAGS_INIT "-B${stdenv.cc.libc}/lib -B${stdenv.cc.libc_dev}/lib -B${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/crt -I${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/clang/21/include -isystem${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/clang/21/include -isysroot ${stdenv.cc.libc_dev} -isystem${stdenv.cc.libc_dev}/include -msse -mmmx -march=native")
  set(CMAKE_CXX_FLAGS_SYCL "-fsycl-host-compiler-options=-nostdinc -nostdinc++ -I${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/clang/21/include -isystem${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/clang/21/include -isysroot ${stdenv.cc.libc_dev} -isystem${stdenv.cc.libc_dev}/include -isystem${stdenv.cc.libc}/include -isystem${stdenv.cc.libc}/usr/include -I${gcc.cc}/include/c++/${gcc.version} -I${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu -I${gcc.cc}/lib/gcc/x86_64-unknown-linux-gnu/${gcc.version}/include -B${stdenv.cc.libc}/lib -B${stdenv.cc.libc_dev}/lib -B${oneapi-torch-dev}/oneapi/compiler/2025.2/lib/crt -msse -mmmx -march=native")
  '';
  cmakeFlags = [
    "-DCMAKE_C_COMPILER=icx"
    "-DCMAKE_CXX_COMPILER=icpx"
    "-DDNNL_GPU_RUNTIME=SYCL"
    "-DDNNL_CPU_RUNTIME=THREADPOOL"
    "-DDNNL_BUILD_TESTS=OFF"
    "-DDNNL_BUILD_EXAMPLES=OFF"
    "-DONEDNN_BUILD_GRAPH=ON"
    "-DDNNL_LIBRARY_TYPE=STATIC"
    "-DDNNL_DPCPP_HOST_COMPILER=g++"
    "-DOpenCL_INCLUDE_DIR=${oneapi-torch-dev}/oneapi/compiler/2025.2/linux/include"
    "-DOpenCL_LIBRARY=${oneapi-torch-dev}/oneapi/compiler/2025.2/linux/lib/libOpenCL.so"
    "-DCMAKE_TOOLCHAIN_FILE=${syclToolchainFile}"
  ];

  installPhase = ''
    mkdir -p $out/lib $out/include
    find . -name '*.a' -exec cp {} $out/lib/ \;
    cp -r include $out/
  '';


}
