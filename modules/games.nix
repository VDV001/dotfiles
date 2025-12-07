{
  nixosModule =
    { pkgs, ... }:

    {
      environment.systemPackages = with pkgs; [
        lutris
        heroic
      ];

      programs.gamescope = {
        enable = true;
        capSysNice = true;
      };
      programs.gamemode.enable = true;

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        gamescopeSession.enable = true;
      };
    };
}
