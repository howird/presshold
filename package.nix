{
  lib,
  rustPlatform,
  pkg-config,
  wrapGAppsHook4,
  gtk4,
  gtk4-layer-shell,
  libx11,
  wtype,
  xdotool,
  ydotool,
  procps,
}: let
  cargoToml = lib.importTOML ./Cargo.toml;
in
  rustPlatform.buildRustPackage {
    pname = cargoToml.package.name;
    inherit (cargoToml.package) version;

    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./Cargo.toml
        ./Cargo.lock
        ./build.rs
        ./src
      ];
    };

    cargoLock.lockFile = ./Cargo.lock;

    nativeBuildInputs = [pkg-config wrapGAppsHook4];
    buildInputs = [gtk4 gtk4-layer-shell libx11];

    # Runtime helpers presshold shells out to for character injection,
    # cursor lookup and desktop / ydotoold detection.
    preFixup = ''
      gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [wtype xdotool ydotool procps]})
    '';

    meta = {
      description = cargoToml.package.description;
      homepage = "https://github.com/jalovisko/presshold";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "presshold";
    };
  }
