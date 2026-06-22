_: {
  configurations.nixos.vm.module =
    { config, ... }:
    {
      mine.base.networking.hostName = "vm";
      virtualisation.vmVariant.virtualisation.graphics = false;
      users.users.${config.mine.base.user.name}.initialPassword = "changeme";
    };
}
