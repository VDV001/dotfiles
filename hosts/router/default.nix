# OpenWrt sysupgrade image for GL-MT6000 (Flint 2)
#
# Requires --impure flag because secrets are read from environment variables.
# Use build.sh which decrypts sops and calls nix build with the right env.
{
  pkgs,
  lib,
}:
let
  version = "25.12.0";
  target = "mediatek/filogic";
  profile = "glinet_gl-mt6000";

  packages = [
    "sing-box"
    "adguardhome"
    "luci"
    "luci-ssl"
    "ttyd"
  ];

  wifiKey = builtins.getEnv "ROUTER_WIFI_KEY";
  pppoeUser = builtins.getEnv "ROUTER_PPPOE_USER";
  pppoePass = builtins.getEnv "ROUTER_PPPOE_PASS";
  vlessUuid = builtins.getEnv "ROUTER_VLESS_UUID";

  hasSecrets = wifiKey != "" && pppoeUser != "" && pppoePass != "" && vlessUuid != "";
in
pkgs.stdenv.mkDerivation {
  pname = "openwrt-gl-mt6000-image";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://downloads.openwrt.org/releases/${version}/targets/${target}/openwrt-imagebuilder-${version}-${
      lib.replaceStrings [ "/" ] [ "-" ] target
    }.Linux-x86_64.tar.zst";
    hash = "sha256-8h9lH6cLlDF/pTUxISE2VB/qA6UiJuzZLI7pAKf/ba8=";
  };

  nativeBuildInputs = with pkgs; [
    zstd
    gnumake
    gawk
    rsync
    perl
    file
    unzip
    bzip2
    fakeroot
    ncurses
    which
    getopt
  ];

  sourceRoot = "openwrt-imagebuilder-${version}-${
    lib.replaceStrings [ "/" ] [ "-" ] target
  }.Linux-x86_64";

  buildPhase = ''
    runHook preBuild

    # Copy custom files
    cp -r ${./files} custom-files
    chmod -R u+w custom-files

    ${lib.optionalString hasSecrets ''
      # Substitute secrets into config files
      sed -i "s/%%WIFI_KEY%%/${wifiKey}/g" custom-files/etc/config/wireless
      sed -i "s/%%PPPOE_USER%%/${pppoeUser}/g" custom-files/etc/config/network
      sed -i "s/%%PPPOE_PASS%%/${pppoePass}/g" custom-files/etc/config/network
      sed -i "s/%%VLESS_UUID%%/${vlessUuid}/g" custom-files/etc/sing-box/config.json
    ''}

    ${lib.optionalString (!hasSecrets) ''
      echo "WARNING: Building without secrets. Config files will contain placeholders."
      echo "Use build.sh or set ROUTER_WIFI_KEY, ROUTER_PPPOE_USER, ROUTER_PPPOE_PASS, ROUTER_VLESS_UUID env vars with --impure."
    ''}

    make image \
      PROFILE="${profile}" \
      PACKAGES="${lib.concatStringsSep " " packages}" \
      FILES="$(pwd)/custom-files"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp bin/targets/${target}/*-sysupgrade.bin $out/sysupgrade.bin
    runHook postInstall
  '';

  meta = {
    description = "OpenWrt ${version} image for GL-MT6000 (Flint 2)";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
