{ lib
, fetchFromGitHub
, fetchurl
, fetchpatch
, fetchpatch2
, callPackage
, pkg-config
, cmake
, ninja
, python3
, gobject-introspection
, wrapGAppsHook
, wrapQtAppsHook
, extra-cmake-modules
, qtbase
, qtwayland
, qtsvg
, qtimageformats
, gtk3
, boost
, fmt
, libdbusmenu
, lz4
, xxHash
, ffmpeg
, openalSoft
, minizip
, libopus
, alsa-lib
, libpulseaudio
, perlPackages
, pipewire
, range-v3
, tl-expected
, hunspell
, glibmm_2_68
, webkitgtk_6_0
, jemalloc
, rnnoise
, protobuf
, abseil-cpp
  # Transitive dependencies:
, util-linuxMinimal
, pcre
, libpthreadstubs
, libXdamage
, libXdmcp
, libselinux
, libsepol
, libepoxy
, at-spi2-core
, libXtst
, libthai
, libdatrie
, xdg-utils
, libsysprof-capture
, libpsl
, brotli
, microsoft-gsl
, mm-common
, rlottie
, stdenv
, darwin
, lld
, libicns
, nix-update-script
}:

# Main reference:
# - This package was originally based on the Arch package but all patches are now upstreamed:
#   https://git.archlinux.org/svntogit/community.git/tree/trunk/PKGBUILD?h=packages/telegram-desktop
# Other references that could be useful:
# - https://git.alpinelinux.org/aports/tree/testing/telegram-desktop/APKBUILD
# - https://github.com/void-linux/void-packages/blob/master/srcpkgs/telegram-desktop/template

let
  tg_owt = callPackage ./tg_owt.nix {
    inherit stdenv;
    abseil-cpp = abseil-cpp.override {
      cxxStandard = "20";
    };
  };
  glibmm = glibmm_2_68.overrideAttrs (attrs: {
    version = "2.78.0";
    src = fetchurl {
      url = "mirror://gnome/sources/glibmm/2.78/glibmm-2.78.0.tar.xz";
      hash = "sha256-XS6HJWSZbwKgbYu6w2d+fDlK+LAN0VJq69R6+EKj71A=";
    };
    patches = [
      # Revert "Glib, Gio: Add new API from glib 2.77.0"
      (fetchpatch2 {
        url = "https://github.com/GNOME/glibmm/commit/5b9032c0298cbb49c3ed90d5f71f2636751fa638.patch";
        revert = true;
        hash = "sha256-UzrzIOnXh9pxuTDQsp6mnunDNNtc86hE9tCe1NgKsyo=";
      })
    ];
    mesonFlags = [
      "-Dmaintainer-mode=true"
      "-Dbuild-documentation=false"
    ];
    nativeBuildInputs = attrs.nativeBuildInputs ++ [
      mm-common
      perlPackages.perl
      perlPackages.XMLParser
    ];
  });
  mainProgram = if stdenv.isLinux then "telegram-desktop" else "Telegram";
in
stdenv.mkDerivation rec {
  pname = "telegram-desktop";
  version = "4.11.8";

  src = fetchFromGitHub {
    owner = "telegramdesktop";
    repo = "tdesktop";
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-VuMcqbGo1t1J7I8kXdqsw/01Mth9YKEbiy8aNtM3azw=";
  };

  patches = [
    ./macos.patch
    # the generated .desktop files contains references to unwrapped tdesktop, breaking scheme handling
    # and the scheme handler is already registered in the packaged .desktop file, rendering this unnecessary
    # see https://github.com/NixOS/nixpkgs/issues/218370
    (fetchpatch {
      url = "https://salsa.debian.org/debian/telegram-desktop/-/raw/09b363ed5a4fcd8ecc3282b9bfede5fbb83f97ef/debian/patches/Disable-register-custom-scheme.patch";
      hash = "sha256-B8X5lnSpwwdp1HlvyXJWQPybEN+plOwimdV5gW6aY2Y=";
    })
  ];

  postPatch = lib.optionalString stdenv.isLinux ''
    substituteInPlace Telegram/ThirdParty/libtgvoip/os/linux/AudioInputALSA.cpp \
      --replace '"libasound.so.2"' '"${alsa-lib}/lib/libasound.so.2"'
    substituteInPlace Telegram/ThirdParty/libtgvoip/os/linux/AudioOutputALSA.cpp \
      --replace '"libasound.so.2"' '"${alsa-lib}/lib/libasound.so.2"'
    substituteInPlace Telegram/ThirdParty/libtgvoip/os/linux/AudioPulse.cpp \
      --replace '"libpulse.so.0"' '"${libpulseaudio}/lib/libpulse.so.0"'
    substituteInPlace Telegram/lib_webview/webview/platform/linux/webview_linux_webkitgtk_library.cpp \
      --replace '"libwebkitgtk-6.0.so.4"' '"${webkitgtk_6_0}/lib/libwebkitgtk-6.0.so.4"'
  '';

  # We want to run wrapProgram manually (with additional parameters)
  dontWrapGApps = true;
  dontWrapQtApps = true;

  nativeBuildInputs = [
    pkg-config
    cmake
    ninja
    python3
    wrapQtAppsHook
  ] ++ lib.optionals stdenv.isLinux [
    gobject-introspection
    wrapGAppsHook
    extra-cmake-modules
  ] ++ lib.optionals stdenv.isDarwin [
    lld
  ];

  buildInputs = [
    qtbase
    qtsvg
    qtimageformats
    boost
    lz4
    xxHash
    ffmpeg
    openalSoft
    minizip
    libopus
    range-v3
    tl-expected
    rnnoise
    protobuf
    tg_owt
    microsoft-gsl
    rlottie
  ] ++ lib.optionals stdenv.isLinux [
    qtwayland
    gtk3
    fmt
    libdbusmenu
    alsa-lib
    libpulseaudio
    pipewire
    hunspell
    glibmm
    webkitgtk_6_0
    jemalloc
    # Transitive dependencies:
    util-linuxMinimal # Required for libmount thus not nativeBuildInputs.
    pcre
    libpthreadstubs
    libXdamage
    libXdmcp
    libselinux
    libsepol
    libepoxy
    at-spi2-core
    libXtst
    libthai
    libdatrie
    libsysprof-capture
    libpsl
    brotli
  ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk_11_0.frameworks; [
    Cocoa
    CoreFoundation
    CoreServices
    CoreText
    CoreGraphics
    CoreMedia
    OpenGL
    AudioUnit
    ApplicationServices
    Foundation
    AGL
    Security
    SystemConfiguration
    Carbon
    AudioToolbox
    VideoToolbox
    VideoDecodeAcceleration
    AVFoundation
    CoreAudio
    CoreVideo
    CoreMediaIO
    QuartzCore
    AppKit
    CoreWLAN
    WebKit
    IOKit
    GSS
    MediaPlayer
    IOSurface
    Metal
    NaturalLanguage
    libicns
  ]);

  env = lib.optionalAttrs stdenv.isDarwin {
    NIX_CFLAGS_LINK = "-fuse-ld=lld";
  };

  cmakeFlags = [
    "-Ddisable_autoupdate=ON"
    # We're allowed to used the API ID of the Snap package:
    "-DTDESKTOP_API_ID=611335"
    "-DTDESKTOP_API_HASH=d524b414d21f4d37f08684c1df41ac9c"
    # See: https://github.com/NixOS/nixpkgs/pull/130827#issuecomment-885212649
    "-DDESKTOP_APP_USE_PACKAGED_FONTS=OFF"
  ];

  preBuild = ''
    # for cppgir to locate gir files
    export GI_GIR_PATH="$XDG_DATA_DIRS"
  '';

  installPhase = lib.optionalString stdenv.isDarwin ''
    mkdir -p $out/Applications
    cp -r ${mainProgram}.app $out/Applications
    ln -s $out/{Applications/${mainProgram}.app/Contents/MacOS,bin}
  '';

  postFixup = lib.optionalString stdenv.isLinux ''
    # This is necessary to run Telegram in a pure environment.
    # We also use gappsWrapperArgs from wrapGAppsHook.
    wrapProgram $out/bin/${mainProgram} \
      "''${gappsWrapperArgs[@]}" \
      "''${qtWrapperArgs[@]}" \
      --suffix PATH : ${lib.makeBinPath [ xdg-utils ]}
  '' + lib.optionalString stdenv.isDarwin ''
    wrapQtApp $out/Applications/${mainProgram}.app/Contents/MacOS/${mainProgram}
  '';

  passthru = {
    inherit tg_owt;
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "Telegram Desktop messaging app";
    longDescription = ''
      Desktop client for the Telegram messenger, based on the Telegram API and
      the MTProto secure protocol.
    '';
    license = licenses.gpl3Only;
    homepage = "https://desktop.telegram.org/";
    changelog = "https://github.com/telegramdesktop/tdesktop/releases/tag/v${version}";
    maintainers = with maintainers; [ nickcao ];
    inherit mainProgram;
  };
}
