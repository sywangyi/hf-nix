{
  buildPythonPackage,
  fetchPypi,
  setuptools,
  huggingface-hub,
}:

buildPythonPackage rec {
  pname = "kernels";
  version = "0.10.1";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Lr6BEU5dQXiwap6jwmNCHHzu4KmViKdAf/gnZTAHuRk=";
  };

  pyproject = true;

  build-system = [ setuptools ];

  dependencies = [
    huggingface-hub
  ];

  pythonImportsCheck = [ "kernels" ];

  meta = {
    description = "Fetch compute kernels from the hub";
  };
}
