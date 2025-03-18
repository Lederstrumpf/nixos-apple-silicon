{ lib
, fetchurl
, mesa
}:

(mesa.override {
  galliumDrivers = [ "softpipe" "llvmpipe" "asahi" ];
  vulkanDrivers = [ "swrast" "asahi" ];
}).overrideAttrs (oldAttrs: {
  version = "25.1.0-asahi";
  src = fetchurl {
    # tracking: https://pagure.io/fedora-asahi/mesa/commits/asahi
    url = "https://sources.voidlinux.org/mesa-asahi-25.1.0%2B20250221/mesa-asahi-20250221.tar.gz";
    sha256 = "sha256-PYxMpIuMxCAFmWi63EUUHWivdi9XysW9tWpq9tftk2k=";
  };

  mesonFlags =
    let
      badFlags = [
        "-Dinstall-mesa-clc"
        "-Dopencl-spirv"
        "-Dgallium-nine"
      ];
      isBadFlagList = f: builtins.map (b: lib.hasPrefix b f) badFlags;
      isGoodFlag = f: !(builtins.foldl' (x: y: x || y) false (isBadFlagList f));
    in
    (builtins.filter isGoodFlag oldAttrs.mesonFlags) ++ [
      # we do not build any graphics drivers these features can be enabled for
      "-Dgallium-va=disabled"
      "-Dgallium-vdpau=disabled"
      "-Dgallium-xa=disabled"
    ];

  # replace patches with ones tweaked slightly to apply to this version
  patches = [
    ./opencl.patch
    ./system-gbm.patch
  ];

  postInstall = (oldAttrs.postInstall or "") + ''
    # we don't build anything to go in this output but it needs to exist
    touch $spirv2dxil
    touch $cross_tools
  '';
})
