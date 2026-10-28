# Upstream release manifest: https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/releases
{
  pkgs,
  lib ? pkgs.lib,
  stdenv ? pkgs.stdenv,
  browserPkg ? pkgs.vivaldi,
  browserProfileDir ? "$HOME/.config/vivaldi",
  useUserProfile ? true,
  extraBwrapArgs ? [ ],
}:
let
  pname = "antigravity";
  version = "2.26.0-6546645232517120";

  sources = {
    x86_64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${version}/linux-x64/Antigravity.tar.gz";
      hash = "sha256-n3lzA3L2hdhJuTUYcjHt6ls4xSaehV40Xmi1xgcfeIQ=";
    };
    aarch64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${version}/linux-arm/Antigravity.tar.gz";
      hash = "sha256-ievaW475b4BoN6786ckGePvxWA+MyNxIm99JoPhhHvM=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "antigravity: unsupported system ${stdenv.hostPlatform.system}");

  src = pkgs.fetchurl {
    inherit (source) url hash;
  };

  meta = {
    description = "Google Antigravity agentic development environment";
    homepage = "https://antigravity.google";
    license = lib.licenses.unfree;
    mainProgram = "antigravity";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "antigravity";
    desktopName = "Antigravity";
    comment = "Google Antigravity agentic development environment";
    genericName = "IDE";
    exec = "antigravity %U";
    icon = "antigravity";
    startupNotify = true;
    startupWMClass = "Antigravity";
    categories = [
      "Development"
      "IDE"
    ];
    mimeTypes = [
      "x-scheme-handler/antigravity"
      "inode/directory"
    ];
  };

  unwrapped = stdenv.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version src meta;

    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    nativeBuildInputs = [
      pkgs.asar
      pkgs.copyDesktopItems
    ];

    desktopItems = [ desktopItem ];

    unpackPhase = ''
      runHook preUnpack
      mkdir -p source
      cd source
      tar -xzf "$src"
      shopt -s nullglob
      entries=( * )
      if [ "''${#entries[@]}" -eq 1 ] && [ -d "''${entries[0]}" ]; then
        cd "''${entries[0]}"
      fi
      shopt -u nullglob
      chmod -R u+w .
      runHook postUnpack
    '';

    postPatch = ''
      packed="resources/app/node_modules.asar"
      unpacked="resources/app/node_modules"
      if [ -f "$packed" ]; then
        asar extract "$packed" "$unpacked"
        sudo_prompt="$unpacked/@vscode/sudo-prompt/index.js"
        if [ -f "$sudo_prompt" ]; then
          substituteInPlace "$sudo_prompt" \
            --replace-quiet "/usr/bin/pkexec" "/run/wrappers/bin/pkexec" \
            --replace-quiet "/bin/bash" "${pkgs.bash}/bin/bash"
        fi
        rm -f "$packed"
        ln -rs "$unpacked" "$packed"
      fi
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/antigravity"
      cp -rT . "$out/lib/antigravity"

      mkdir -p "$out/lib/antigravity/resources/bin"
      cat << 'EOF' > "$out/lib/antigravity/resources/bin/antigravity-tunnel"
      #!/usr/bin/env bash
      echo "antigravity-tunnel is unavailable in NixOS FHS build" >&2
      exit 0
      EOF
      chmod +x "$out/lib/antigravity/resources/bin/antigravity-tunnel"

      icon_src=""
      if [ -f "resources/app.asar" ]; then
        asar list "resources/app.asar" > "$TMPDIR/asar-files.txt"
        if icon_entry="$(grep -m1 -E '(^|/)icon\.png$' "$TMPDIR/asar-files.txt")"; then
          asar extract-file "resources/app.asar" "''${icon_entry#/}"
          if [ -f "icon.png" ]; then
            icon_src="icon.png"
          fi
        fi
      fi
      if [ -z "$icon_src" ] && [ -f "resources/app/resources/linux/code.png" ]; then
        icon_src="resources/app/resources/linux/code.png"
      fi
      if [ -n "$icon_src" ]; then
        install -Dm644 "$icon_src" "$out/share/pixmaps/antigravity.png"
        install -Dm644 "$icon_src" "$out/share/icons/hicolor/1024x1024/apps/antigravity.png"
      fi

      runHook postInstall
    '';
  };

  browserExe = lib.getExe browserPkg;
  browserCommand = builtins.baseNameOf browserExe;

  chromeLauncher = pkgs.writeShellScript "antigravity-chrome-wrapper" (
    ''
      target_bin="${browserExe}"
      if [ -x "/run/current-system/sw/bin/${browserCommand}" ]; then
        target_bin="/run/current-system/sw/bin/${browserCommand}"
      fi
    ''
    + (
      if useUserProfile then
        ''
          exec "$target_bin" \
            --user-data-dir="${browserProfileDir}" \
            --profile-directory=Default \
            "$@"
        ''
      else
        ''
          exec "$target_bin" "$@"
        ''
    )
  );

  chromeWrapper = pkgs.runCommand "antigravity-chrome-shims" { } ''
    mkdir -p "$out/bin"
    ln -s ${chromeLauncher} "$out/bin/google-chrome-stable"
    ln -s ${chromeLauncher} "$out/bin/google-chrome"
  '';

  launcherScript = pkgs.writeShellScript "antigravity-launcher" (
    ''
      export CHROME_BIN="${chromeWrapper}/bin/google-chrome-stable"
      export CHROME_PATH="${chromeWrapper}/bin/google-chrome-stable"
      export ALSA_PLUGIN_DIR="''${ALSA_PLUGIN_DIR:-${pkgs.pipewire}/lib/alsa-lib}"
    ''
    + lib.optionalString useUserProfile ''
      chrome_cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/google-chrome"
      devtools_port="$chrome_cfg_dir/DevToolsActivePort"
      mkdir -p "$chrome_cfg_dir"
      if [ -L "$devtools_port" ] || [ ! -e "$devtools_port" ]; then
        ln -sfn "${browserProfileDir}/DevToolsActivePort" "$devtools_port"
      fi
    ''
    + ''
      app_bin=""
      for candidate in antigravity Antigravity antigravity-hub; do
        if [ -x "${unwrapped}/lib/antigravity/$candidate" ]; then
          app_bin="${unwrapped}/lib/antigravity/$candidate"
          break
        fi
      done

      if [ -z "$app_bin" ]; then
        echo "antigravity: executable not found in ${unwrapped}/lib/antigravity" >&2
        exit 1
      fi

      ozone_flags=()
      if [ -n "''${NIXOS_OZONE_WL:-}" ] && [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        ozone_flags=(
          "--ozone-platform-hint=auto"
          "--enable-features=WaylandWindowDecorations"
          "--enable-wayland-ime=true"
          "--wayland-text-input-version=3"
        )
      fi

      exec "$app_bin" "''${ozone_flags[@]}" "$@"
    ''
  );
in
pkgs.buildFHSEnv {
  inherit pname version meta;

  dieWithParent = false;

  targetPkgs = fhsPkgs: [
    fhsPkgs.alsa-lib
    fhsPkgs.at-spi2-atk
    fhsPkgs.at-spi2-core
    fhsPkgs.atk
    fhsPkgs.cairo
    fhsPkgs.cups
    fhsPkgs.dbus
    fhsPkgs.expat
    fhsPkgs.glib
    fhsPkgs.gsettings-desktop-schemas
    fhsPkgs.gtk3
    fhsPkgs.libdrm
    fhsPkgs.libgbm
    fhsPkgs.libglvnd
    fhsPkgs.libnotify
    fhsPkgs.libpulseaudio
    fhsPkgs.libsecret
    fhsPkgs.libudev0-shim
    fhsPkgs.libuuid
    fhsPkgs.libx11
    fhsPkgs.libxcb
    fhsPkgs.libxcomposite
    fhsPkgs.libxcursor
    fhsPkgs.libxdamage
    fhsPkgs.libxext
    fhsPkgs.libxfixes
    fhsPkgs.libxi
    fhsPkgs.libxkbcommon
    fhsPkgs.libxkbfile
    fhsPkgs.libxrandr
    fhsPkgs.libxrender
    fhsPkgs.libxscrnsaver
    fhsPkgs.libxshmfence
    fhsPkgs.libxtst
    fhsPkgs.nspr
    fhsPkgs.nss
    fhsPkgs.pango
    fhsPkgs.stdenv.cc.cc.lib
    fhsPkgs.systemdLibs
    fhsPkgs.udev
    fhsPkgs.vulkan-loader
    fhsPkgs.wayland
    fhsPkgs.zlib
    browserPkg
    (lib.hiPrio chromeWrapper)
  ];

  extraBwrapArgs = [
    "--bind-try /etc/nixos/ /etc/nixos/"
    "--ro-bind-try /etc/xdg/ /etc/xdg/"
    "--ro-bind-try /etc/nixpkgs/ /etc/nixpkgs/"
  ]
  ++ extraBwrapArgs;

  extraInstallCommands = ''
    ln -s ${unwrapped}/share $out/share
  '';

  passthru = {
    inherit unwrapped;
  };

  runScript = launcherScript;
}
