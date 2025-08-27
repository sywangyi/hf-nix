{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  filelock,
  huggingface-hub,
  numpy,
  packaging,
  pyyaml,
  regex,
  requests,
  tokenizers,
  safetensors,
  tqdm,
}:

buildPythonPackage rec {
  pname = "transformers";
  version = "4.55.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "huggingface";
    repo = "transformers";
    tag = "v${version}";
    hash = "sha256-dS9Xb8y/s+YpNDo6H0kO8X61C/K+SlCBLzW1JOzF4Uk=";
  };

  build-system = [ setuptools ];

  dependencies = [
    filelock
    huggingface-hub
    numpy
    packaging
    pyyaml
    regex
    requests
    tokenizers
    safetensors
    tqdm
  ];

  # Many tests require internet access.
  doCheck = false;

  pythonImportsCheck = [ "transformers" ];

  meta = {
    homepage = "https://github.com/huggingface/transformers";
    description = "Natural Language Processing for TensorFlow 2.0 and PyTorch";
    mainProgram = "transformers-cli";
    changelog = "https://github.com/huggingface/transformers/releases/tag/v${version}";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ ];
  };
}
