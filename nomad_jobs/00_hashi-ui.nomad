job "hashi-ui" {
  datacenters = ["sds"]
  type        = "service"

  group "server" {
    count = 1

    task "hashi-ui" {
      driver = "docker"

      config {
        image        = "jippi/hashi-ui"
        network_mode = "host"
      }

      service {
        port = "http"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }

      env {
        NOMAD_ENABLE = 1
        NOMAD_ADDR   = "http://192.168.78.11:4646"

        CONSUL_ENABLE = 1
        CONSUL_ADDR   = "192.168.78.11:8500"
      }

      resources {
        cpu    = 500
        memory = 512

        network {
          mbits = 5

          port "http" {
            static = 3000
          }
        }
      }
    }
  }
}
