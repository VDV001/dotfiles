{
  homeModule =
    { ... }:

    {
      home.file.".ssh/sockets/.keep".text = "";

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        includes = [
          "~/.colima/ssh_config"
          "~/.orbstack/ssh/config"
        ];
        matchBlocks."*" = {
          addKeysToAgent = "yes";
          controlMaster = "auto";
          controlPath = "~/.ssh/sockets/%r@%h-%p";
          controlPersist = "600";
        };
      };
    };
}
