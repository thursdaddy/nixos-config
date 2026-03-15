_: {
  configurations.nixos.vm.module =
    { config, ... }:
    {
      virtualisation.vmVariant.virtualisation.graphics = false;
      users.users.${config.mine.base.user.name}.initialPassword = "changeme";
    };
}
