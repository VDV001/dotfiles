{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        postgresql
        # Линтер миграций Postgres: его зовут гейты migrations-lint в pre-push
        # birka, deal-sense и floq. Из PATH он работает офлайн; без него гейт
        # идёт через `nix shell nixpkgs#squawk` и на чистой машине тянет сеть.
        squawk
      ];
    };
}
