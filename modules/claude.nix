{
  homeModule =
    { config, ... }:
    {
      sops.secrets.context7_api_key = { };

      sops.templates."mcp.json" = {
        path = "${config.home.homeDirectory}/.mcp.json";
        content = builtins.toJSON {
          mcpServers = {
            context7 = {
              type = "http";
              url = "https://mcp.context7.com/mcp";
              headers = {
                CONTEXT7_API_KEY = config.sops.placeholder.context7_api_key;
              };
            };
          };
        };
      };

      programs.claude-code = {
        enable = true;

        mcpServers = {
          "claude-flow@alpha" = {
            command = "npx";
            args = [
              "claude-flow@alpha"
              "mcp"
              "start"
            ];
            type = "stdio";
          };

          ruv-swarm = {
            command = "npx";
            args = [
              "ruv-swarm@latest"
              "mcp"
              "start"
            ];
            type = "stdio";
          };

          playwright = {
            command = "npx";
            args = [
              "@playwright/mcp@latest"
              "--browser"
              "chromium"
            ];
            type = "stdio";
          };

          taskmaster-ai = {
            command = "npx";
            args = [
              "-y"
              "task-master-ai"
            ];
            type = "stdio";
          };
        };
      };
    };
}
