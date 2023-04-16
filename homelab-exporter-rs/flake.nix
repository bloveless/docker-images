{
  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        frameworks = pkgs.darwin.apple_sdk.frameworks;
        rust = (pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain ).override {
            extensions = [
              "clippy-preview"
              "rust-src"
            ];
          };
      in
      with pkgs;
      {
        devShells.default = mkShell {
          buildInputs = [
            openssl
            pkg-config
            exa
            fd
            rust
          ] ++ (
            lib.optionals stdenv.isDarwin [
              frameworks.Security
              frameworks.CoreServices
              frameworks.CoreFoundation
              frameworks.Foundation
            ]
          );

          shellHook = ''
            alias ls=exa
            alias find=fd
          '';
        };
      }
    );
}
