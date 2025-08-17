{
  runCommand,
  oneapi-torch-dev,
  dpcppVersion,
  ptiVersion
}:

runCommand "oneapi-bintools-unwrapped" { preferLocalBuild = true; } ''
  mkdir -p $out/bin

  # Link all executables from oneapi-torch-dev's bin directory
  for prog in ${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}/bin/*; do
    if [ -f "$prog" ]; then
      ln -sf "$prog" "$out/bin/$(basename "$prog")"
    fi
  done

  # If there is a compiler subdirectory, link those too
  if [ -d ${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}/bin/compiler ]; then
    for prog in ${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}/bin/compiler/*; do
      if [ -f "$prog" ]; then
        ln -sf "$prog" "$out/bin/$(basename "$prog")"
      fi
    done
  fi

  mkdir -p $out/nix-support
  echo 'export SYCL_ROOT="${oneapi-torch-dev}/oneapi/compiler/${dpcppVersion}"' >> $out/nix-support/setup-hook
  echo 'export Pti_DIR="${oneapi-torch-dev}/oneapi/pti/${ptiVersion}/lib/cmake/pti"' >> $out/nix-support/setup-hook
''
