{
  pkgs,
  lib,
  username,
  userdesc,
  config,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  sops = {
    defaultSopsFile = ../../secrets/linode-vps.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      vless_uuid_dfjay = { };
      vless_uuid_user2 = { };
      reality_private_key = { };
      reality_public_key = { };
      reality_short_id = { };
    };
    templates = {
      "sing-box-config.json" = {
        content = builtins.toJSON {
          log = {
            level = "info";
            timestamp = true;
          };
          inbounds = [
            {
              type = "vless";
              tag = "vless-in";
              listen = "::";
              listen_port = 8443;
              users = [
                {
                  uuid = config.sops.placeholder.vless_uuid_dfjay;
                  flow = "";
                }
                {
                  uuid = config.sops.placeholder.vless_uuid_user2;
                  flow = "";
                }
              ];
              tls = {
                enabled = true;
                server_name = "www.microsoft.com";
                reality = {
                  enabled = true;
                  handshake = {
                    server = "www.microsoft.com";
                    server_port = 443;
                  };
                  private_key = config.sops.placeholder.reality_private_key;
                  short_id = [ config.sops.placeholder.reality_short_id ];
                };
              };
            }
          ];
          outbounds = [
            {
              type = "direct";
              tag = "direct";
            }
          ];
        };
      };
      "vless-subscription-dfjay" = {
        content = "vless://${config.sops.placeholder.vless_uuid_dfjay}@subs.dfjay.com:8443?encryption=none&security=reality&sni=www.microsoft.com&fp=chrome&pbk=${config.sops.placeholder.reality_public_key}&sid=${config.sops.placeholder.reality_short_id}&type=tcp&flow=#dfjay-vps";
      };
      "vless-subscription-user2" = {
        content = "vless://${config.sops.placeholder.vless_uuid_user2}@subs.dfjay.com:8443?encryption=none&security=reality&sni=www.microsoft.com&fp=chrome&pbk=${config.sops.placeholder.reality_public_key}&sid=${config.sops.placeholder.reality_short_id}&type=tcp&flow=#user2-vps";
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;

  users = {
    defaultUserShell = pkgs.bash;
    mutableUsers = true;
    users.${username} = {
      isNormalUser = true;
      description = userdesc;
      extraGroups = [ "wheel" ];
      initialPassword = "changeme"; # for LISH console only, change after first login
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDE9M/4cz4CbBLjyZlTDaS+MXK5X4wx+Jbap3TN1dRyO9NbXhIkaxNf/FRjKWkuluOeX59m5MsUHccG5D5L5QCUxZigl5oHmWk4Gwc+WNx5R9rSwxiI6fhzWUzyduyKnHlz/UMTmGyvG0Xc/FGMS9TKNaz6lXSyRZtCWaDhsR12URJ7MxkYuU483UT/TS6jcO6k0w+WTCXbdBz4XsK7bKFMbh1Ed36VM4Y/UxCYP4W2VHrLd4+BvqX760bIab0PH5FWHl9Kzg0ff/7Q97atUeMd5r0GfZfS5+SEDORW07rjdeRailE0aq3xDwvugx27BcqCWbIDibSwPjrpZsG1oEfGZ41P+IxEYIIN5YCM4c8MT7hUZ9/ramhIK93pVl5tnlXHloi9VmYiXneGply43DyNw6aGtGquV6AxM7Lz/YtYxr9gK5rFO/L8ZaBmorDSKgROY9GxC7varnZxLb+t6zlSDCz035eH1/8bd0ak7p1TVZnPgx285DzuAcCTaPddLAc= dfjay@Pavels-MacBook-Pro.local"
      ];
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = false;
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP / Caddy
      443 # HTTPS / Caddy
      8443 # sing-box VLESS
    ];
    allowedUDPPorts = [
      8443 # sing-box UDP
    ];
  };

  services.caddy = {
    enable = true;
    email = "mail@dfjay.com"; # for Let's Encrypt notifications

    virtualHosts."dfjay.com".extraConfig = ''
      respond "Welcome" 200
    '';

    virtualHosts."subs.dfjay.com".extraConfig = ''
      root * /var/lib/caddy/subscription
      file_server
    '';
  };

  services.sing-box = {
    enable = true;
    settings = { }; # Configuration loaded from sops template
  };

  # Override sing-box to use sops-generated config
  systemd.services.sing-box.serviceConfig = {
    ExecStart = lib.mkForce [
      "${pkgs.sing-box}/bin/sing-box run -c ${config.sops.templates."sing-box-config.json".path}"
    ];
  };

  # Subscription file generator (using sops template)
  systemd.services.subscription-generator = {
    description = "Generate VLESS subscription file";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/caddy/subscription

      # Base64 encode subscriptions from sops templates
      ${pkgs.coreutils}/bin/base64 -w 0 ${config.sops.templates."vless-subscription-dfjay".path} > /var/lib/caddy/subscription/dfjay
      ${pkgs.coreutils}/bin/base64 -w 0 ${config.sops.templates."vless-subscription-user2".path} > /var/lib/caddy/subscription/user2

      # Set proper permissions
      chown -R caddy:caddy /var/lib/caddy/subscription
      chmod 644 /var/lib/caddy/subscription/*
    '';
  };

  environment.systemPackages = with pkgs; [
    curl
    wget
    vim
    htop
    git
    mtr
    inetutils
    sysstat
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  security.sudo.enable = true;

  system.stateVersion = "25.05";
}
