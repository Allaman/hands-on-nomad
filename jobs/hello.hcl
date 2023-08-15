job "hello" {
  datacenters = ["dc1"]

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "hello" {
    count = 3

    network {
      mode = "bridge"
      port "http" {}
    }

    service {
      name     = "hello"
      port     = "http"
      provider = "nomad"
      check {
        name     = "nginx_probe"
        type     = "http"
        interval = "10s"
        timeout  = "1s"
        port     = "http"
        path     = "/"
      }
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Path(`/hello`)",
      ]
    }

    task "hello" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:latest"
        ports = ["http"]
        args  = [
          "-listen", ":${NOMAD_PORT_http}",
          "-text", "Hello and welcome to ${NOMAD_IP_http} running on port ${NOMAD_PORT_http}",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
