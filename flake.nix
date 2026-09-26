{
  description = "presshold: macOS-style accent character selector for Linux";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: {
      presshold = pkgs.callPackage ./package.nix {};
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.presshold;
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        inputsFrom = [self.packages.${pkgs.stdenv.hostPlatform.system}.presshold];
        packages = with pkgs; [cargo rustc rust-analyzer clippy rustfmt];
      };
    });

    overlays.default = final: _prev: {
      presshold = final.callPackage ./package.nix {};
    };

    # Runs presshold as a systemd user service. The user also needs to be in
    # the `input` and `uinput` groups (NixOS: hardware.uinput.enable = true).
    homeManagerModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.services.presshold;
    in {
      options.services.presshold = {
        enable = lib.mkEnableOption "presshold accent character selector";
        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.presshold;
          description = "The presshold package to use.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [cfg.package];

        systemd.user.services.presshold = {
          Unit = {
            Description = "presshold is a macOS-style accent character selector";
            Documentation = "https://github.com/jalovisko/presshold";
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            Type = "simple";
            ExecStart = lib.getExe cfg.package;
            Restart = "on-failure";
            RestartSec = 3;
            TimeoutStartSec = 5;
          };
          Install.WantedBy = ["graphical-session.target"];
        };
      };
    };
  };
}
