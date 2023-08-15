job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port  "http"{
         static = 6543
      }
    }

    service {
      name = "traefik-http"
      provider = "nomad"
      port = "http"
      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"
      identity {
        env = true
        file = true
      }
      template {
        data = <<EOH
# dynamic_conf.toml
[http]
  [http.routers]
    [http.routers.my-api]
      rule = "Host(`{{ env "NOMAD_IP_http" }}`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))"
      service = "api@internal"
      middlewares = ["auth"]
  [http.middlewares]
    [http.middlewares.auth.basicAuth]
      users = [
        {{- with nomadVar "nomad/jobs/traefik/traefik/server" }}
        "{{ .BASIC_AUTH }}",
        {{- end }}
      ]
EOH
        destination = "local/dynamic_conf.toml"
      }
      template {
        data = <<EOH
[entryPoints]
  [entryPoints.web]
    # Expose the services
    address = ":{{ env "NOMAD_PORT_http" }}"
[log]
  level = "DEBUG"
[api]
  dashboard = true
[providers]
  [providers.file]
    filename = "/etc/traefik/dynamic_conf.toml"
  [providers.nomad]
    namespaces = ["dev", "default"]
    [providers.nomad.endpoint]
      address = "http://{{ env "NOMAD_IP_http" }}:4646"
EOH
        destination = "local/traefik.toml"
      }
      config {
        image = "traefik"
        ports = ["http"]
        volumes = [
          "local/dynamic_conf.toml:/etc/traefik/dynamic_conf.toml",
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }
    }
  }
}
