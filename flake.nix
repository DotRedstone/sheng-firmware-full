{
  description = "Firmware for Xiaomi Pad 6S Pro (sheng), including DSP sensor blobs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.stdenvNoCC.mkDerivation {
      pname = "sheng-firmware-full";
      version = "1.0.0";

      src = ./.;

      dontFixup = true;
      dontStrip = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        # Create standard directories
        mkdir -p $out/lib/firmware/qcom/sm8550/sheng
        mkdir -p $out/lib/firmware/rfsa/adsp
        mkdir -p $out/lib/firmware/nanosic
        mkdir -p $out/bin
        mkdir -p $out/lib64
        mkdir -p $out/etc/sensors

        # 1. Base firmware
        if [ -d "qcom" ]; then
            cp -r qcom/* $out/lib/firmware/qcom/
        fi

        # 2. ADSP / Hexagon DSP blobs
        if [ -d "firmware/rfsa/adsp" ]; then
            cp -r firmware/rfsa/adsp/* $out/lib/firmware/rfsa/adsp/
        fi
        
        # 2b. Nanosic Firmware
        if [ -d "nanosic" ]; then
            cp -r nanosic/* $out/lib/firmware/nanosic/
        fi

        # 3. Executables
        if [ -d "bin" ]; then
            cp -r bin/* $out/bin/
            chmod +x $out/bin/adsprpcd
        fi

        # 4. Libraries
        # Note: Bionic Android libs are not directly usable by glibc, but we ship them just in case they are needed for hybris/proot.
        if [ -d "lib64" ]; then
            cp -r lib64/* $out/lib64/
        fi
        if [ -d "lib" ]; then
            # We skip copying the entire /vendor/lib to avoid conflicting with Linux's /lib structure,
            # or we can place them in a safe vendor path. We'll copy them to /usr/lib/android-vendor/lib
            mkdir -p $out/usr/lib/android-vendor/lib
            cp -r lib/* $out/usr/lib/android-vendor/lib/
        fi

        # 5. Configurations
        if [ -d "etc/sensors" ]; then
            cp -r etc/sensors/* $out/etc/sensors/
        fi

        runHook postInstall
      '';
      };
    });
  };
}
