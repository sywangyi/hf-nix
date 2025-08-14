{
  runCommand,
  oneapi-torch-dev,
}:

runCommand "oneapi-bintools-unwrapped" { preferLocalBuild = true; } ''
  mkdir -p $out/bin

  # Link all executables from oneapi-torch-dev's bin directory
  for prog in ${oneapi-torch-dev}/oneapi/compiler/2025.2/bin/*; do
    if [ -f "$prog" ]; then
      ln -sf "$prog" "$out/bin/$(basename "$prog")"
    fi
  done

  # If there is a compiler subdirectory, link those too
  if [ -d ${oneapi-torch-dev}/oneapi/compiler/2025.2/bin/compiler ]; then
    for prog in ${oneapi-torch-dev}/oneapi/compiler/2025.2/bin/compiler/*; do
      if [ -f "$prog" ]; then
        ln -sf "$prog" "$out/bin/$(basename "$prog")"
      fi
    done
  fi
''
