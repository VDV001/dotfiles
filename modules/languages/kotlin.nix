{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        kotlin
        #kotlin-native
        ktlint
      ];
    };
}
