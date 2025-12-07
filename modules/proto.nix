{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        protobuf
        protobuf-language-server
        protoc-gen-go
        protoc-gen-go-grpc
      ];
    };
}
