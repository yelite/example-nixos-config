{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: {
    nixosConfigurations = {
      vm-dev = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hardware-configuration.nix
          ({pkgs, ...}: {
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            system.stateVersion = "23.11";

            services.openssh.enable = true;
            services.openssh.settings.PasswordAuthentication = true;
            services.openssh.settings.PermitRootLogin = "no";

            environment.systemPackages = with pkgs; [
              git # used for nixos-rebuild
              open-vm-tools
              neovim
            ];
            virtualisation.vmware.guest.enable = true;

            fileSystems."/host" = {
              fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
              device = ".host:/";
              options = [
                "umask=22"
                "allow_other"
                "defaults"
              ];
            };

            environment.etc = {
              "nixos/flake.nix" = {
                source = "/host/nixos-config/flake.nix";
              };
            };
            networking.hostName = "vm-dev";

            users.users.liteye = {
              isNormalUser = true;
              extraGroups = ["wheel"];
            };
          })
        ];
      };
    };
  };
}
