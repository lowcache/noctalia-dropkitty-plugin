{
  description = "dropkitty — a Noctalia drop-down terminal plugin. Dev shell and offline checks.";

  # Pinned: newer luau-analyze dropped --definitions, which the syntax gate needs.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/56c02bc00adcf003215cc4bd996d6efaf4cff188";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
    in
    {
      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ bats shellcheck luau stylua jq gnumake ];
        };
      });
    };
}
