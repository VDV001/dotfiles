{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.colima/ssh_config"
      "~/.orbstack/ssh"
    ];
    matchBlocks."*" = {
      addKeysToAgent = "yes";
    };
  };
}
