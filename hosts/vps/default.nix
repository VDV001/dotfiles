{ modules }:

{
  system = "x86_64-linux";
  user = "dfjay";
  useremail = "mail@dfjay.com";
  userdesc = "Pavel Yozhikov";
  nixosStateVersion = "24.11";
  homeStateVersion = "25.11";

  modules = with modules; [
    locale

    bat
    btop
    eza
    git
    helix
    ripgrep
    starship
    yazi
    zoxide
  ];

  # Colmena deployment settings
  colmena = {
    targetHost = "directvpn.dfjay.com";
    targetUser = "dfjay";
  };

  config =
    {
      pkgs,
      lib,
      config,
      inputs,
      username,
      userdesc,
      ...
    }:
    let
      vpnUsers = [
        "dfjay"
        "chu74"
        "chu52"
      ];
    in
    {
      imports = [
        ./hardware-configuration.nix
      ];

      sops = {
        defaultSopsFile = ../../secrets/vps.yaml;
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets = {
          reality_private_key = { };
          reality_public_key = { };
          warp_private_key = { };
          warp_ipv4 = { };
          warp_ipv6 = { };
        }
        // builtins.listToAttrs (
          map (u: {
            name = "vless_uuid_${u}";
            value = { };
          }) vpnUsers
        );
        templates = {
          "sing-box-config.json" = {
            restartUnits = [ "sing-box.service" ];
            content = builtins.toJSON {
              log = {
                level = "info";
                timestamp = true;
              };
              dns = {
                servers = [
                  {
                    tag = "quad9";
                    type = "https";
                    server = "dns.quad9.net";
                    domain_resolver = "bootstrap";
                  }
                  {
                    tag = "bootstrap";
                    type = "udp";
                    server = "9.9.9.9";
                  }
                ];
                final = "quad9";
                strategy = "prefer_ipv4";
              };
              inbounds = [
                {
                  type = "vless";
                  tag = "vless-reality-in";
                  listen = "127.0.0.1";
                  listen_port = 8444;
                  users = map (u: {
                    uuid = config.sops.placeholder."vless_uuid_${u}";
                    flow = "xtls-rprx-vision";
                  }) vpnUsers;
                  tls = {
                    enabled = true;
                    server_name = "www.samsung.com";
                    reality = {
                      enabled = true;
                      handshake = {
                        server = "www.samsung.com";
                        server_port = 443;
                      };
                      private_key = config.sops.placeholder.reality_private_key;
                      short_id = [ "1a3287df" ];
                    };
                  };
                }
              ];
              endpoints = [
                {
                  type = "wireguard";
                  tag = "warp";
                  mtu = 1280;
                  address = [
                    config.sops.placeholder.warp_ipv4
                    config.sops.placeholder.warp_ipv6
                  ];
                  private_key = config.sops.placeholder.warp_private_key;
                  peers = [
                    {
                      address = "engage.cloudflareclient.com";
                      port = 2408;
                      public_key = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
                      allowed_ips = [
                        "0.0.0.0/0"
                        "::/0"
                      ];
                    }
                  ];
                }
              ];
              outbounds = [
                {
                  type = "direct";
                  tag = "direct";
                }
              ];
              route = {
                final = "warp";
                default_domain_resolver = "bootstrap";
              };
            };
          };
        }
        // builtins.listToAttrs (
          map (u: {
            name = "vless-subscription-${u}";
            value = {
              restartUnits = [ "subscription-generator.service" ];
              content = "vless://${
                config.sops.placeholder."vless_uuid_${u}"
              }@directvpn.dfjay.com:443?encryption=none&flow=xtls-rprx-vision&type=tcp&security=reality&sni=www.samsung.com&fp=chrome&pbk=${config.sops.placeholder.reality_public_key}&sid=1a3287df#${u}-reality";
            };
          }) vpnUsers
        )
        // builtins.listToAttrs (
          map (u: {
            name = "sing-box-client-${u}.json";
            value = {
              restartUnits = [ "subscription-generator.service" ];
              content = builtins.toJSON {
                log = {
                  level = "info";
                  timestamp = true;
                };
                dns = {
                  servers = [
                    {
                      tag = "proxy-dns";
                      type = "https";
                      server = "dns.quad9.net";
                      detour = "proxy-reality";
                      domain_resolver = "bootstrap-dns";
                    }
                    {
                      tag = "direct-dns";
                      type = "udp";
                      server = "77.88.8.8";
                      detour = "direct";
                    }
                    {
                      tag = "bootstrap-dns";
                      type = "udp";
                      server = "9.9.9.9";
                      detour = "direct";
                    }
                  ];
                  rules = [
                    {
                      rule_set = [ "geosite-category-ru" ];
                      action = "route";
                      server = "direct-dns";
                    }
                  ];
                  final = "proxy-dns";
                  strategy = "prefer_ipv4";
                };
                inbounds = [
                  {
                    type = "tun";
                    tag = "tun-in";
                    address = [
                      "172.19.0.1/30"
                      "fdfe:dcba:9876::1/126"
                    ];
                    auto_route = true;
                    strict_route = true;
                    sniff = true;
                  }
                ];
                outbounds = [
                  {
                    type = "vless";
                    tag = "proxy-reality";
                    server = "directvpn.dfjay.com";
                    server_port = 443;
                    uuid = config.sops.placeholder."vless_uuid_${u}";
                    flow = "xtls-rprx-vision";
                    tls = {
                      enabled = true;
                      server_name = "www.samsung.com";
                      reality = {
                        enabled = true;
                        public_key = config.sops.placeholder.reality_public_key;
                        short_id = "1a3287df";
                      };
                      utls = {
                        enabled = true;
                        fingerprint = "chrome";
                      };
                    };
                  }
                  {
                    type = "direct";
                    tag = "direct";
                  }
                ];
                route = {
                  rules = [
                    {
                      protocol = "dns";
                      action = "hijack-dns";
                    }
                    {
                      ip_is_private = true;
                      action = "route";
                      outbound = "direct";
                    }
                    {
                      rule_set = [ "geosite-category-ru" ];
                      action = "route";
                      outbound = "direct";
                    }
                    {
                      rule_set = [ "geoip-ru" ];
                      action = "route";
                      outbound = "direct";
                    }
                  ];
                  rule_set = [
                    {
                      tag = "geosite-category-ru";
                      type = "remote";
                      format = "binary";
                      url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ru.srs";
                      download_detour = "direct";
                    }
                    {
                      tag = "geoip-ru";
                      type = "remote";
                      format = "binary";
                      url = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ru.srs";
                      download_detour = "direct";
                    }
                  ];
                  final = "proxy-reality";
                  default_domain_resolver = "bootstrap-dns";
                };
              };
            };
          }) vpnUsers
        );
      };

      security.sudo.wheelNeedsPassword = false;

      users = {
        defaultUserShell = pkgs.bash;
        mutableUsers = true;
        users.${username} = {
          isNormalUser = true;
          description = userdesc;
          extraGroups = [ "wheel" ];
          initialPassword = "changeme"; # for console only, change after first login
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9W6B9WBu7PbMJWdKGFzBLMR1y2IK+kFuSsIWh2fwqg dfjay@dfjay-laptop.local"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMFmvdG0pEwUZcsrElS/5B+jR9PYfEECrtgy8VLs5pwR cardno:20_488_896"
          ];
        };
      };

      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = lib.mkForce "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          MaxAuthTries = 3;
          X11Forwarding = false;
          AllowAgentForwarding = false;
        };
      };

      services.fail2ban = {
        enable = true;
        maxretry = 3;
        bantime = "1h";
      };

      networking.firewall = {
        enable = true;
        logRefusedConnections = true;
        allowedTCPPorts = [
          22 # SSH
          80 # HTTP (ACME + redirect)
          443 # nginx stream → SNI routing
        ];
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "mail@dfjay.com";
      };

      services.nginx = {
        enable = true;

        # Layer 4 SNI routing — all traffic enters on :443
        streamConfig = ''
          map $ssl_preread_server_name $backend {
            dfjay.com       127.0.0.1:8443;
            subs.dfjay.com  127.0.0.1:8443;
            default         127.0.0.1:8444;
          }
          server {
            listen 443;
            listen [::]:443;
            ssl_preread on;
            proxy_pass $backend;
          }
        '';

        virtualHosts."dfjay.com" = {
          forceSSL = true;
          enableACME = true;
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
            {
              addr = "[::]";
              port = 80;
            }
            {
              addr = "127.0.0.1";
              port = 8443;
              ssl = true;
            }
            {
              addr = "[::1]";
              port = 8443;
              ssl = true;
            }
          ];
          root = "${inputs.portfolio}";
          locations."/".tryFiles = "$uri $uri/ /index.html";
        };

        virtualHosts."subs.dfjay.com" = {
          forceSSL = true;
          enableACME = true;
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
            {
              addr = "[::]";
              port = 80;
            }
            {
              addr = "127.0.0.1";
              port = 8443;
              ssl = true;
            }
            {
              addr = "[::1]";
              port = 8443;
              ssl = true;
            }
          ];
          root = "/var/lib/nginx/subscription";
          locations."~ ^/([a-f0-9]+)/sing-box$".extraConfig = ''
            default_type application/json;
            try_files /$1/sing-box/config =404;
          '';
          locations."~ ^/([a-f0-9]+)/?$".extraConfig = ''
            default_type text/plain;
            add_header profile-update-interval "24";
            try_files /$1/base64 =404;
          '';
        };
      };

      services.sing-box = {
        enable = true;
        settings = { }; # Configuration loaded from sops template
      };

      # Override sing-box to use sops-generated config
      systemd.services.sing-box = {
        serviceConfig = {
          ExecStart = lib.mkForce [
            "" # Clear the original ExecStart (required by systemd)
            "${pkgs.sing-box}/bin/sing-box run -c ${config.sops.templates."sing-box-config.json".path}"
          ];
        };
      };

      # Subscription file generator (using sops template)
      systemd.services.subscription-generator = {
        description = "Generate VLESS Reality subscription file";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [ pkgs.coreutils ];
        script = ''
          DEST="/var/lib/nginx/subscription"
          STAGE=$(mktemp -d "$DEST.XXXXXX")
          ${lib.concatMapStringsSep "\n" (u: ''
            USER_TOKEN=$(sha256sum ${config.sops.secrets."vless_uuid_${u}".path} | cut -c1-32)
            BASE="$STAGE/$USER_TOKEN"
            mkdir -p "$BASE/sing-box"
            base64 -w 0 ${config.sops.templates."vless-subscription-${u}".path} > "$BASE/base64"
            cp ${config.sops.templates."sing-box-client-${u}.json".path} "$BASE/sing-box/config"
            echo "${u} $USER_TOKEN" >> "$STAGE/tokens.txt"
          '') vpnUsers}
          chown -R nginx:nginx "$STAGE"
          chmod -R u=rwX,go=rX "$STAGE"
          rm -rf "$DEST"
          mv "$STAGE" "$DEST"
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
        tcpdump
      ];

      security.sudo.enable = true;
    };
}
