{ stdenv, fetchFromGitHub, cmake, ninja, python3, gcc, oneapi-torch-dev, writeShellScriptBin, dpcppVersion}:

stdenv.mkDerivation rec {
  pname = "onednn-xpu";
  version = "3.8.1";

  src = fetchFromGitHub {
    owner = "oneapi-src";
    repo = "oneDNN";
    rev = "v3.8.1";
    sha256 = "sha256-x4leRd0xPFUygjAv/D125CIXn7lYSyzUKsd9IDh/vCc=";
  };

  env.CXXFLAGS = "-isystem${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}/lib/clang/21/include -I${stdenv.cc.libc_dev}/include -I${gcc.cc}/include/c++/${gcc.version}  -I${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu";
  env.LDFLAGS =
    "-L${stdenv.cc}/lib -L${stdenv.cc}/lib64 -L${stdenv.cc.libc_dev}/lib -L${stdenv.cc.libc_dev}/lib64 -L${stdenv.cc.libc_dev}/usr/lib" +
    " -L${gcc.cc}/lib/gcc/x86_64-unknown-linux-gnu/${gcc.version}" +
    " -L${stdenv.cc.cc.lib}/lib";

  nativeBuildInputs = [
    (writeShellScriptBin "icx" ''
      exec ${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}/bin/icx \
      -B${stdenv.cc.libc}/lib -B${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}/lib/crt -isysroot ${stdenv.cc.libc_dev} -isystem${stdenv.cc.libc_dev}/include \
      "$@"
    '')
    (writeShellScriptBin "icpx" ''
      exec ${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}/bin/icpx \
      -B${stdenv.cc.libc}/lib -B${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}/lib/crt -isysroot ${stdenv.cc.libc_dev} -isystem${stdenv.cc.libc_dev}/include \
      "$@"
    '')
    (writeShellScriptBin "g++" ''
      exec ${gcc.cc}/bin/g++ \
        -nostdinc  \
        -isysroot ${stdenv.cc.libc_dev} \
        -isystem${stdenv.cc.libc_dev}/include \
        -I${gcc.cc}/include/c++/${gcc.version} \
        -I${gcc.cc}/include/c++/${gcc.version}/x86_64-unknown-linux-gnu \
        -I${gcc.cc}/lib/gcc/x86_64-unknown-linux-gnu/${gcc.version}/include \
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
  ];

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
    "-DOpenCL_INCLUDE_DIR=${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}/linux/include"
    "-DOpenCL_LIBRARY=${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}/linux/lib/libOpenCL.so"
  ];

  installPhase = ''
    mkdir -p $out/lib $out/include
    find . -name '*.a' -exec cp {} $out/lib/ \;
    cp -r include $out/
  '';
}
