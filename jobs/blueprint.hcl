job "blueprint" {
  datacenters = ["dc1"]
  namespace = "dev"

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "blueprint" {
    count = 1

    network {
      mode = "bridge"
      port "web" {}
    }

    service {
      name     = "blueprint"
      port     = "web"
      provider = "nomad"
      check {
        name     = "blueprint_probe"
        type     = "http"
        interval = "10s"
        timeout  = "1s"
        port     = "web"
        path     = "/actuator/health/readiness"
      }
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Path(`/blueprint`)",
        "traefik.http.routers.myrouter.rule=Host(`localhost`)"
      ]
    }

    task "server" {
      driver = "java"

      artifact {
        source      = "https://github.com/ralfhecktor/architecture-blueprint/releases/download/v1.0.0/architecture-blueprint-infrastructure-0.0.2-20230612.195936-1.jar"
        destination = "local/app.jar"
        mode        = "file"
      }

      config {
        jar_path    = "local/app.jar"
        jvm_options = ["-Xmx2048m", "-Xms256m", "-Dserver.port=${NOMAD_PORT_web}"]
      }
      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
