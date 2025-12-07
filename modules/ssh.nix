{
  homeModule =
    { ... }:

    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        includes = [
          "~/.colima/ssh_config"
        ];
        matchBlocks."*" = {
          addKeysToAgent = "yes";
        };
      };
    };
}
