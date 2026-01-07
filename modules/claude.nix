{
  homeModule =
    { config, ... }:
    {
      sops.secrets.ref_api_key = { };
      sops.secrets.magic_21st_api_key = { };
      sops.secrets.figma_api_key = { };

      # MCP servers with secrets go to ~/.mcp.json via sops template
      sops.templates."mcp.json" = {
        path = "${config.home.homeDirectory}/.mcp.json";
        content = builtins.toJSON {
          mcpServers = {
            # Documentation search
            Ref = {
              type = "http";
              url = "https://api.ref.tools/mcp";
              headers = {
                x-ref-api-key = config.sops.placeholder.ref_api_key;
              };
            };

            # UI component builder (21st.dev)
            "21st-magic" = {
              type = "stdio";
              command = "npx";
              args = [
                "-y"
                "@21st-dev/magic@latest"
              ];
              env = {
                API_KEY = config.sops.placeholder.magic_21st_api_key;
              };
            };

            # Figma design context
            figma-context = {
              type = "stdio";
              command = "npx";
              args = [
                "-y"
                "figma-developer-mcp"
                "--figma-api-key=${config.sops.placeholder.figma_api_key}"
                "--stdio"
              ];
            };
          };
        };
      };

      programs.claude-code = {
        enable = true;

        mcpServers = {
          # Web to MCP converter
          web-to-mcp = {
            type = "http";
            url = "https://web-to-mcp.com/mcp/4db00515-c569-46ef-97d3-26ae8f8fe865/";
          };

          # Browser automation
          playwright = {
            command = "npx";
            args = [
              "-y"
              "@playwright/mcp@latest"
            ];
            type = "stdio";
          };

          # Magic UI components
          magic-ui = {
            command = "npx";
            args = [
              "-y"
              "@magicuidesign/mcp@latest"
            ];
            type = "stdio";
          };

          # Nx workspace tools
          nx-mcp = {
            command = "npx";
            args = [
              "-y"
              "nx-mcp@latest"
            ];
            type = "stdio";
          };

          # Sequential thinking for complex problems
          sequential-thinking = {
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-sequential-thinking"
            ];
            type = "stdio";
          };

          # Task Master AI for project management
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
