{
  lib,
  libllvm,
  optimize ? "Debug",
  stdenv,
  revision,
  zig,
}:
stdenv.mkDerivation {
  pname = "nanofetch";
  version = revision;
  src = ./..;

  nativeBuildInputs = [
    libllvm
    zig
  ];

  buildPhase = ''
    mkdir -p .cache
    export ZIG_LOCAL_CACHE_DIR=$(pwd)/.cache
    export ZIG_GLOBAL_CACHE_DIR=$(pwd)/.cache
    zig build -Doptimize=${optimize}
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp zig-out/bin/nanofetch $out/bin/
    llvm-strip $out/bin/nanofetch
  '';

  meta = {
    description = "Lightning fast Linux fetch tool in Zig";
    homepage = "https://github.com/amadejkastelic/nanofetch";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
}
