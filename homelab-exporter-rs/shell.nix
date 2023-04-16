{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell rec {
    buildInputs = with pkgs; [
      # clang
      # llvmPackages.bintools
      # rustup
      pkg-config
      openssl
    ];
    # RUSTC_VERSION = pkgs.lib.readFile ./rust-toolchain;
    # # https://github.com/rust-lang/rust-bindgen#environment-variables
    # LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];
    # shellHook = ''
    #   export PATH=$PATH:''${CARGO_HOME:-~/.cargo}/bin
    #   export PATH=$PATH:''${RUSTUP_HOME:-~/.rustup}/toolchains/$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin/
    #   '';
    # Add libvmi precompiled library to rustc search path
    RUSTFLAGS = (builtins.map (a: ''-L ${a}/lib'') [
      pkgs.openssl.dev
    ]);

    # BINDGEN_EXTRA_CLANG_ARGS =
    # # # Includes with normal include path
    # (builtins.map (a: ''-I"${a}/include"'') [
    #   # pkgs.libvmi
    #   # pkgs.glibc.dev
    #   pkgs.openssl.dev
    # ]);
    # # Includes with special directory paths
    # ++ [
    #   ''-I"${pkgs.llvmPackages_latest.libclang.lib}/lib/clang/${pkgs.llvmPackages_latest.libclang.version}/include"''
    #   ''-I"${pkgs.glib.dev}/include/glib-2.0"''
    #   ''-I${pkgs.glib.out}/lib/glib-2.0/include/''
    # ];
  }
