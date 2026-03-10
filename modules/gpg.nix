{
  homeModule =
    { ... }:

    {
      programs.gpg.enable = true;
      services.gpg-agent.enable = true;
      services.gpg-agent.enableSshSupport = true;
    };

  darwinModule =
    { ... }:
    {
      environment.variables.SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
    };
}
