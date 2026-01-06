{
  mkShell,
  zig,
  zls,
}:
mkShell {
  name = "nanofetch";
  packages = [
    zig
    zls
  ];
}
