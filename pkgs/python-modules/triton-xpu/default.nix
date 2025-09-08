{
  stdenv,
  buildPythonPackage,
  setuptools,
  distutils,
  wheel,
  fetchFromGitHub,
  triton-llvm,
  xpuPackages,
  torchVersion ? "2.7",
  cmake,
  ninja,
  lib,
  python,
  pybind11,
  pkg-config,
  pkgs,
}:

let
  torchTritonVersions = {
    "2.7" = {
      llvm_rev = "1188b1ff7b956cb65d8ddda5f1e56c432f1a57c7";
      llvm_hash = "sha256-iwG0bWnrVX9xbHB4eIe/JxQNFdDHb/COXo4d0joOlDE=";
      triton_rev = "0bcc8265e677e5321606a3311bf71470f14456a8";
      triton_hash = "sha256-R5UbAVIjIBFuBB9Nf638MloZWddTk/sqFNFhqtuD/DI=";
      spirv_llvm_rev = "4eea290c449fca2efd28cfa46d3946c5feaf988c";
      spirv_llvm_hash = "sha256-IBPlhtkFxghvq1FGRqQJYtA3P6vZmpkDANZaAhnLtKc=";
      spirv_head_rev = "2b2e05e088841c63c0b6fd4c9fb380d8688738d3";
      spirv_head_hash = "sha256-EZrWquud9CFrDNdskObCQQCR0HsXOZmJohh/0ybaT7g=";
      buildPhaseStr = ''
        cd python
        ${python.pythonOnBuildForHost.interpreter} setup.py bdist_wheel
      '';
    };
    "2.8" = {
      llvm_rev = "e12cbd8339b89563059c2bb2a312579b652560d0";
      llvm_hash = "sha256-BtMEDk7P7P5k+s2Eb1Ej2QFvjl0A8gN7Tq/Kiu+Pqe4=";
      triton_rev = "ae324eeac8e102a2b40370e341460f3791353398";
      triton_hash = "sha256-rHy/gIH3pYYlmSd6OuRJdB3mJvzeVI2Iav9rszCeV8I=";
      spirv_llvm_rev = "96f5ade29c9088ea89533a7e3ca70a9f9464f343";
      spirv_llvm_hash = "sha256-phbljvV08uWhFJie7XrodLIc97vU4o7zAI1zonN4krY=";
      spirv_head_rev = "c9aad99f9276817f18f72a4696239237c83cb775";
      spirv_head_hash = "sha256-/KfUxWDczLQ/0DOiFC4Z66o+gtoF/7vgvAvKyv9Z9OA=";
      buildPhaseStr = ''
        ${python.pythonOnBuildForHost.interpreter} setup.py bdist_wheel
      '';
    };
  };
  tritonVersions =
    torchTritonVersions.${torchVersion} or (throw "Unsupported Torch version: ${torchVersion}");

  llvmBase = triton-llvm.override {
    llvmTargetsToBuild = [
      "X86"
      "SPIRV"
    ];
  };
  llvm = llvmBase.overrideAttrs (old: {
    src = fetchFromGitHub {
      owner = "llvm";
      repo = "llvm-project";
      rev = tritonVersions.llvm_rev;
      hash = tritonVersions.llvm_hash;
    };
    pname = "triton-llvm-xpu";
    outputs = [ "out" ];
  });
in

buildPythonPackage rec {
  pname = "triton-xpu";
  version = torchVersion;
  format = "other";
  dontUseCmakeConfigure = true;

  src = fetchFromGitHub {
    owner = "intel";
    repo = "intel-xpu-backend-for-triton";
    rev = tritonVersions.triton_rev;
    hash = tritonVersions.triton_hash;
  };

  spirvLlvmTranslatorSrc = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-LLVM-Translator";
    rev = tritonVersions.spirv_llvm_rev;
    hash = tritonVersions.spirv_llvm_hash;
  };

  spirvHeadersSrc = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-Headers";
    rev = tritonVersions.spirv_head_rev;
    hash = tritonVersions.spirv_head_hash;
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  build-system = with python.pkgs; [
    lit
    pip
  ];

  buildInputs = [
    llvm
    xpuPackages.oneapi-torch-dev
    pybind11
    pkgs.libxml2.dev
  ];

  propagatedBuildInputs = [
    setuptools
    distutils
    wheel
  ];

  buildPhase = tritonVersions.buildPhaseStr;

  installPhase = ''
    WHEEL=$(find $PWD -name "*.whl" | head -n1)
    echo "Found wheel: $WHEEL"
    ${python.pythonOnBuildForHost.interpreter} -m pip install --no-deps --prefix=$out "$WHEEL"
  '';

  pythonImportsCheck = [
    "triton"
    "triton.language"
  ];

  postPatch = ''
      sed -i '/if (NOT SPIRVToLLVMTranslator_FOUND)/,/endif (NOT SPIRVToLLVMTranslator_FOUND)/c\
    set(SPIRVToLLVMTranslator_SOURCE_DIR "${spirvLlvmTranslatorSrc}")\n\
    set(SPIRVToLLVMTranslator_BINARY_DIR \''${CMAKE_CURRENT_BINARY_DIR}/SPIRVToLLVMTranslator-build)\n\
    set(LLVM_CONFIG \''${LLVM_LIBRARY_DIR}/../bin/llvm-config)\n\
    set(LLVM_DIR \''${LLVM_LIBRARY_DIR}/cmake/llvm CACHE PATH "Path to LLVM build dir " FORCE)\n\
    set(LLVM_SPIRV_BUILD_EXTERNAL YES CACHE BOOL "Build SPIRV-LLVM Translator as external" FORCE)\n\
    set(LLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR ${spirvHeadersSrc})\n\
    add_subdirectory(\''${SPIRVToLLVMTranslator_SOURCE_DIR} \''${CMAKE_CURRENT_BINARY_DIR}/SPIRVToLLVMTranslator-build)\n\
    set(SPIRVToLLVMTranslator_INCLUDE_DIR \''${SPIRVToLLVMTranslator_SOURCE_DIR}/include CACHE INTERNAL "SPIRVToLLVMTranslator_INCLUDE_DIR")\n\
    find_package_handle_standard_args(\n\
            SPIRVToLLVMTranslator\n\
            FOUND_VAR SPIRVToLLVMTranslator_FOUND\n\
            REQUIRED_VARS\n\
                SPIRVToLLVMTranslator_SOURCE_DIR)\n\
    ' third_party/intel/cmake/FindSPIRVToLLVMTranslator.cmake
  '';

  # Set LLVM env vars for build
  env = {
    LLVM_INCLUDE_DIRS = "${llvm}/include";
    LLVM_LIBRARY_DIR = "${llvm}/lib";
    LLVM_SYSPATH = "${llvm}";
    TRITON_OFFLINE_BUILD = 1;
    TRITON_BUILD_PROTON = 0;
  };
}
