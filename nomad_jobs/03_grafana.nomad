job "grafana" {
  datacenters = ["sds"]
  type = "service"

  group "grafana" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay = "10s"
      mode = "fail"
    }

    task "grafana" {
      driver = "docker"
      config {
        image = "grafana/grafana:latest"
        mounts = [
          {
            type = "volume"
            target = "/var/lib/grafana"
            source = "name=grafana,size=5G,repl=3"
            volume_options {
              driver_config {
                name = "pxd"
              }
            }
          }
        ]
        port_map {
          http = 3000
        }
      }

      env {
        GF_LOG_MODE = "console"
        GF_SERVER_ROOT_URL = "http://192.168.78.11/grafana"
        GF_SERVER_SERVE_FROM_SUB_PATH = "true"
        GF_AUTH_ANONYMOUS_ENABLED = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE = "Admin"
        GF_AUTH_DISABLE_LOGIN_FORM = "true"
      }

      resources {
        network {
          mbits = 10
          port  "http"  {}
        }
      }

      service {
        name = "grafana"
        tags = ["urlprefix-/grafana"]
        port = "http"
        check {
          name     = "grafana http alive"
          type     = "http"
          path     = "/api/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

    }
  }
}
