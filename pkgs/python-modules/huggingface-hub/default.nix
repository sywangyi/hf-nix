{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  filelock,
  fsspec,
  hf-xet,
  packaging,
  pyyaml,
  requests,
  tqdm,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "huggingface-hub";
  version = "0.34.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "huggingface";
    repo = "huggingface_hub";
    tag = "v${version}";
    hash = "sha256-2R4G/2VBj/URVdVn/1dPBDdFCdXZymPc2zdbzddyYwU=";
  };

  build-system = [ setuptools ];

  dependencies = [
    filelock
    fsspec
    packaging
    pyyaml
    requests
    tqdm
    typing-extensions
  ];
  
  optional-dependencies = {
    xet = [ hf-xet ];
  };

  # Tests require network access
  doCheck = false;
  
  # Skip runtime deps check for optional dependencies
  dontCheckRuntimeDeps = true;

  pythonImportsCheck = [ "huggingface_hub" ];

  meta = {
    homepage = "https://github.com/huggingface/huggingface_hub";
    description = "The official Python client for the Hugging Face Hub";
    changelog = "https://github.com/huggingface/huggingface_hub/releases/tag/v${version}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
  };
}